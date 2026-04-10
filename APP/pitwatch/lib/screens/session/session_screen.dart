import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pitwatch/models/pothole.dart';
import 'package:pitwatch/providers/pothole_provider.dart';
import 'package:pitwatch/services/report_service.dart';
import 'package:pitwatch/screens/session/sessionCompleteScreen.dart';

// Runs in an isolate: compress bytes to JPG and return base64.
String _encodeAndCompressImageIsolate(List<int> bytes) {
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return '';
    final resized = img.copyResize(image, width: 640);
    final jpg = img.encodeJpg(resized, quality: 75);
    return base64Encode(jpg);
  } catch (_) {
    return '';
  }
}

class SessionScreen extends ConsumerStatefulWidget {
  final Duration? sessionDuration;
  const SessionScreen({Key? key, this.sessionDuration}) : super(key: key);

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  Timer? _periodicTimer;
  Timer? _recBlinkTimer;
  Timer? _elapsedTimer;
  final List<Future> _processingTasks = [];
  int _hazardsCount = 0;
  final List<PotholeDetection> _sessionDetections = [];
  DateTime? _sessionStart;
  bool _recOn = true;
  String _elapsedDisplay = '00:00';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initializeFuture = _controller!.initialize();
      await _initializeFuture;

      _sessionStart = DateTime.now();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final diff = DateTime.now().difference(_sessionStart!);
        final mm = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
        final ss = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
        setState(() => _elapsedDisplay = '$mm:$ss');
      });

      _recBlinkTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        if (!mounted) return;
        setState(() => _recOn = !_recOn);
      });

      _periodicTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _captureAndQueue(),
      );
      setState(() {});
    } catch (e) {
      debugPrint('camera init error: $e');
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _recBlinkTimer?.cancel();
    _elapsedTimer?.cancel();
    for (final _ in _processingTasks) {}
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndQueue() async {
    if (!mounted) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final XFile file = await _controller!.takePicture();
      final task = _processAndSend(File(file.path));
      _processingTasks.add(task);
      task.whenComplete(() => _processingTasks.remove(task));
    } catch (e) {
      debugPrint('capture error: $e');
    }
  }

  Future<void> _processAndSend(File file) async {
    try {
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      String b64 = '';
      try {
        b64 = await compute(_encodeAndCompressImageIsolate, bytes);
      } catch (e) {
        debugPrint('compute encode failed: $e');
      }
      if (b64.isEmpty) b64 = base64Encode(bytes);

      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}

      try {
        final body = json.encode({
          'image_base64': b64,
          'confidence_threshold': 0.25,
        });
        final resp = await http
            .post(
              Uri.parse('https://pitwatch-api.onrender.com/predict'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 20));

        // log raw response and decoded payload
        debugPrint(
          'predict response status=${resp.statusCode} body=${resp.body}',
        );
        final decoded = json.decode(resp.body) as Map<String, dynamic>;
        debugPrint('predict decoded: $decoded');

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          if (decoded['status'] == 'success') {
            final detections = (decoded['detections'] as List?) ?? [];
            if (detections.isNotEmpty) {
              if (mounted) setState(() => _hazardsCount += detections.length);

              Position? pos;
              try {
                final serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (serviceEnabled) {
                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied)
                    permission = await Geolocator.requestPermission();
                  if (permission != LocationPermission.denied &&
                      permission != LocationPermission.deniedForever) {
                    pos = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                  }
                }
              } catch (_) {
                pos = null;
              }
              pos ??= Position(
                latitude: 0.0,
                longitude: 0.0,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );

              final List<PotholeDetection> added = [];
              int idx = 0;
              for (final d in detections) {
                try {
                  final Map<String, dynamic> det = Map<String, dynamic>.from(
                    d as Map,
                  );
                  final className = (det['class_name'] ?? 'pothole').toString();
                  final conf = (det['confidence'] as num?)?.toDouble() ?? 0.0;
                  Severity sev = Severity.unknown;
                  final lc = className.toLowerCase();
                  if (lc.contains('low')) sev = Severity.low;
                  if (lc.contains('medium')) sev = Severity.medium;
                  if (lc.contains('high')) sev = Severity.high;

                  final pd = PotholeDetection(
                    id: DateTime.now().millisecondsSinceEpoch + idx,
                    title: className,
                    description:
                        'Auto-detected (confidence ${conf.toStringAsFixed(2)})',
                    severity: sev,
                    status: PotholeStatus.reported,
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                    createdAt: DateTime.now().toIso8601String(),
                  );

                  added.add(pd);

                  try {
                    ref.read(sessionPotholesProvider.notifier).add(pd.toJson());
                  } catch (_) {}
                  await _saveDetection(pd.toJson());

                  try {
                    final postRes = await ReportService.postReport(pd);
                    debugPrint('postReport result: $postRes');
                    if (postRes['ok'] == true) {
                      try {
                        if (postRes['data'] is Map<String, dynamic>) {
                          final serverMap = Map<String, dynamic>.from(
                            postRes['data'],
                          );
                          final serverPd = PotholeDetection.fromJson(serverMap);
                          ref
                              .read(potholeProvider.notifier)
                              .addDetection(serverPd);
                        } else {
                          ref.read(potholeProvider.notifier).addDetection(pd);
                        }

                        final current = ref.read(sessionPotholesProvider);
                        final filtered = current.where((m) {
                          try {
                            final idRaw = m['id'] ?? m['identifier'];
                            if (idRaw is int) return idRaw != pd.id;
                            if (idRaw is String)
                              return int.tryParse(idRaw) != pd.id;
                          } catch (_) {}
                          return true;
                        }).toList();
                        final sessionNotifier = ref.read(
                          sessionPotholesProvider.notifier,
                        );
                        sessionNotifier.clear();
                        for (final m in filtered) sessionNotifier.add(m);
                      } catch (e) {
                        debugPrint('apply server response failed: $e');
                      }
                    }
                  } catch (e) {
                    debugPrint('Immediate post failed: $e');
                  }

                  idx++;
                } catch (e) {
                  debugPrint('detection parse error: $e');
                }
              }

              if (added.isNotEmpty && mounted)
                setState(() => _sessionDetections.addAll(added));
            }
          }
        }
      } catch (e) {
        debugPrint('predict request failed: $e');
      }
    } catch (e) {
      debugPrint('processAndSend error: $e');
    }
  }

  Future<void> _saveDetection(Map<String, dynamic> entry) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/detections.json');
      List existing = [];
      if (await file.exists()) {
        final contents = await file.readAsString();
        if (contents.trim().isNotEmpty)
          existing = json.decode(contents) as List;
      }
      existing.add(entry);
      await file.writeAsString(json.encode(existing));
    } catch (_) {}
  }

  void _endSession() {
    _periodicTimer?.cancel();
    _recBlinkTimer?.cancel();
    _elapsedTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(
          detections: ref.read(sessionPotholesProvider),
          hazards: _hazardsCount,
          durationMinutes: _sessionStart == null
              ? 0
              : DateTime.now().difference(_sessionStart!).inMinutes,
          kilometers: 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chipMaxWidth = math.min(140.0, screenWidth * 0.36);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // camera preview or placeholder
          Positioned.fill(
            child: _controller != null && _controller!.value.isInitialized
                ? CameraPreview(_controller!)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2B3A4A), Color(0xFF18222D)],
                      ),
                    ),
                  ),
          ),

          // translucent overlay to darken preview
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),

          // top HUD (left hazards, center REC, right duration)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: chipMaxWidth),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Hazards',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$_hazardsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: chipMaxWidth),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: const Text(
                                  'Duration',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _elapsedDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // centered REC chip
                  Positioned(
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _recOn
                                  ? Colors.red
                                  : Colors.red.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'REC',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // bottom stop + label (use SafeArea to avoid bottom overflow)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _endSession,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'Monitoring Active',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
