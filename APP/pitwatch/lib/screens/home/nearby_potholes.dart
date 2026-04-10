import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NearbyPotholesScreen extends ConsumerStatefulWidget {
  const NearbyPotholesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyPotholesScreen> createState() =>
      _NearbyPotholesScreenState();
}

class _NearbyPotholesScreenState extends ConsumerState<NearbyPotholesScreen> {
  bool _loading = true;
  Position? _position;
  final List<Map<String, dynamic>> _reports = [];
  final List<Marker> _markers = [];
  final MapController _mapController = MapController();

  static const String _nearbyEndpoint =
      'https://pitwatch.onrender.com/api/v1/reports/nearby/';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNearby());
  }

  Future<bool> _ensureLocationPermissionLocal() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) return false;

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable it in settings.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchNearby() async {
    setState(() => _loading = true);

    final ok = await _ensureLocationPermissionLocal();
    if (!ok) {
      setState(() => _loading = false);
      return;
    }

    try {
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Failed to get position: $e');
      setState(() => _loading = false);
      return;
    }

    if (_position == null) {
      setState(() => _loading = false);
      return;
    }

    // Center the map on the user's location as soon as we have it.
    _centerMapToPosition(_position!);

    final lat = _position!.latitude;
    final lng = _position!.longitude;

    final uri = Uri.parse(
      '$_nearbyEndpoint?lat=$lat&lng=$lng&radius_km=2&limit=50',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final headers = {
        'Accept': 'application/json',
        'User-Agent': 'pitwatch/1.0',
      };
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }

      final resp = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = jsonDecode(resp.body);
        List items = [];
        if (body is List)
          items = body;
        else if (body is Map && body['results'] is List)
          items = body['results'];

        // Log fetched reports for debugging
        try {
          debugPrint('📡 Nearby reports: ${jsonEncode(items)}');
        } catch (e) {
          debugPrint('📡 Nearby reports (raw): $items');
        }

        _reports.clear();
        _markers.clear();

        for (final it in items) {
          try {
            if (it is Map<String, dynamic>) {
              final latVal =
                  (it['latitude'] ?? it['lat'] ?? it['y']) as dynamic;
              final lngVal =
                  (it['longitude'] ?? it['lng'] ?? it['x']) as dynamic;
              if (latVal == null || lngVal == null) continue;
              final dlat = (latVal is num)
                  ? latVal.toDouble()
                  : double.tryParse(latVal.toString());
              final dlng = (lngVal is num)
                  ? lngVal.toDouble()
                  : double.tryParse(lngVal.toString());
              if (dlat == null || dlng == null) continue;

              _reports.add(it);

              _markers.add(
                Marker(
                  point: LatLng(dlat, dlng),
                  width: 44.w,
                  height: 44.w,
                  child: GestureDetector(
                    onTap: () => _showReportDetails(it),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.report_problem,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          } catch (_) {}
        }
      } else {
        debugPrint('Nearby fetch failed: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error fetching nearby: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showReportDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (c) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title']?.toString() ?? 'Pothole',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text('Status: ${item['status'] ?? 'unknown'}'),
              SizedBox(height: 6.h),
              Text('Reported: ${item['created_at'] ?? '-'}'),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _centerMapToPosition(Position p) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(LatLng(p.latitude, p.longitude), 13.0);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : LatLng(19.0760, 72.8777);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Potholes'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 13.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.pitwatch.app',
                  tileProvider: NetworkTileProvider(),
                ),
                if (_position != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        width: 40.w,
                        height: 40.w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
              ],
            ),

            if (_loading) const Center(child: CircularProgressIndicator()),

            Positioned(
              right: 16.w,
              bottom: 24.h,
              child: FloatingActionButton(
                onPressed: () {
                  _fetchNearby();
                },
                child: const Icon(Icons.refresh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
