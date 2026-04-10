import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:pitwatch/screens/home/main_screen.dart';
import 'drowsiness_alert_screen.dart';



DateTime? sessionStartTime;
int alertCount = 0;
DateTime? lastProcessed;

class EyeMonitoringScreen extends StatefulWidget {
  const EyeMonitoringScreen({super.key});

  @override
  State<EyeMonitoringScreen> createState() => _EyeMonitoringScreenState();
}

class _EyeMonitoringScreenState extends State<EyeMonitoringScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;

  bool _isDetecting = false;
  bool isAlertShowing = false;

  DateTime? eyesClosedTime;

  @override
  void initState() {
    sessionStartTime = DateTime.now();
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.05, //
      ),
    );

    if (mounted) {
      _cameraController!.startImageStream(processCameraImage);
      setState(() {});
    }
  }

  Future<void> processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    if (lastProcessed != null &&
        DateTime.now().difference(lastProcessed!).inMilliseconds < 300) {
      return;
    }

    _isDetecting = true;
    lastProcessed = DateTime.now();

    try {

      final bytes = image.planes[0].bytes;


      final sensorOrientation =
          _cameraController!.description.sensorOrientation;
      final imageRotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          rotation: imageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;

        final leftEye = face.leftEyeOpenProbability ?? 1.0;
        final rightEye = face.rightEyeOpenProbability ?? 1.0;

        print("Left: $leftEye | Right: $rightEye");

        if (leftEye < 0.4 && rightEye < 0.4) {
          eyesClosedTime ??= DateTime.now();

          final closedFor =
              DateTime.now().difference(eyesClosedTime!).inSeconds;
          print(" Eyes closed for ${closedFor}s");

          if (closedFor >= 2) {
            onDrowsinessDetected();
          }
        } else {
          eyesClosedTime = null;
        }
      } else {
        print(" No face detected");
        eyesClosedTime = null;
      }
    } catch (e) {
      print(" Detection error: $e");
    }

    _isDetecting = false;
  }

  void onDrowsinessDetected() {
    alertCount++;
    if (isAlertShowing) return;

    isAlertShowing = true;
    eyesClosedTime = null;

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DrowsinessAlertScreen(),
      ),
    ).then((_) {
      eyesClosedTime = null;
      isAlertShowing = false;
    });
  }

  void onStopDetection() {
    final duration = DateTime.now().difference(sessionStartTime!);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize!.height,
                height: _cameraController!.value.previewSize!.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),


          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Monitoring...",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),


          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: onStopDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4E52),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Stop Detection",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}