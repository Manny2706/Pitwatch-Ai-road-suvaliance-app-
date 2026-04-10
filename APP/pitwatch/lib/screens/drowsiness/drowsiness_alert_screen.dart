import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:pitwatch/screens/home/main_screen.dart';

class DrowsinessAlertScreen extends StatefulWidget {
  const DrowsinessAlertScreen({super.key});

  @override
  State<DrowsinessAlertScreen> createState() => _DrowsinessAlertScreenState();
}

class _DrowsinessAlertScreenState extends State<DrowsinessAlertScreen> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _sosTimer;
  Timer? _countdownTimer;
  int _countdown = 10;

  @override
  void initState() {
    super.initState();
    playAlarm();
    startSosCountdown();
    startCountdownUI();
  }

  Future<void> playAlarm() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/alarm.mp3'));
  }

  Future<void> stopAlarm() async {
    await _player.stop();
  }

  void startSosCountdown() {
    _sosTimer = Timer(const Duration(seconds: 10), () {
      triggerSosCall();
    });
  }

  void startCountdownUI() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> triggerSosCall() async {
    // 1. Make the emergency call
    final Uri uri = Uri(scheme: 'tel', path: '6306671439');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    // 2. Send alert email via Django backend
    await sendAlertEmail();

    // 3. Close the screen
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> sendAlertEmail() async {
    try {
      // Get current location
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw 'Location services are disabled.';
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw 'Location permissions are denied';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw 'Location permissions are permanently denied';
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Location error: $e');
        // Use default coordinates if location fails
        position = Position(
          latitude: 45.1256,
          longitude: 48.4562,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      final response = await http
          .post(
            Uri.parse(
              'https://pitwatch.onrender.com/api/v1/reports/emergency/',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzc2MDM0ODAwLCJpYXQiOjE3NzU4NTQ4MDAsImp0aSI6IjMxNTQ0MGM4MDdiMDQwOThiOWU3YWIzNWJkNjRlY2ZmIiwidXNlcl9pZCI6MX0.TiRSoD_BUIRPUpQRGpxvB92PCYsOpm90rXgP-hJmA48',
            },
            body: jsonEncode({
              'recipient_mail': 'knowledgesmart24@gmail.com',
              'latitude': position.latitude,
              'longitude': position.longitude,
              'title': 'Sharda University road',
              'description': 'person in probably in danger, send police',
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Emergency report sent successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert sent!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint(
          '❌ Failed to send emergency report: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send alert: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on TimeoutException {
      debugPrint('⏱️ Emergency report request timed out');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert request timed out. Server may be waking up.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔥 Error sending emergency report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    _countdownTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon
              const Icon(Icons.warning_rounded, color: Colors.white, size: 100),
              const SizedBox(height: 20),

              // Title
              const Text(
                "WAKE UP!",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "Eyes closed for too long",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Countdown display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "SOS in $_countdown seconds...",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // I'm Awake Button
              SizedBox(
                width: 200,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    _sosTimer?.cancel();
                    _countdownTimer?.cancel();
                    await stopAlarm();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "I'm Awake",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
