import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pitwatch/models/pothole.dart';

/// Minimal provider: expose only four pieces of data as requested:
/// - persisted total detections list (state)
/// - integer `totalCount` storing total number of persisted detections
/// - session detections list (maps)
/// - integer `sessionCount` storing number of detections in current session
class PotholeNotifier extends StateNotifier<List<PotholeDetection>> {
  PotholeNotifier() : super([]) {
    _init();
  }

  static const _kReportsKey = 'cached_reports_v1';

  // Session-only detections (maps) collected during an active session.
  final List<Map<String, dynamic>> _sessionDetections = [];

  // A simple integer storing the total persisted detection count.
  int totalCount = 0;

  Future<void> _init() async {
    await loadFromPrefs();
  }

  /// Access the persisted detections list (immutable view via `ref.watch(potholeProvider)`).
  List<PotholeDetection> get allDetections => state;

  /// Session detections as immutable list of maps.
  List<Map<String, dynamic>> get sessionDetections =>
      List.unmodifiable(_sessionDetections);

  /// Number of detections captured in the current session.
  int get sessionCount => _sessionDetections.length;

  /// Add a persisted detection (deduplicates by id).
  void addDetection(PotholeDetection detection) {
    final exists = state.any((d) => d.id == detection.id);
    if (exists) return;
    state = [...state, detection];
    totalCount = state.length;
    saveToPrefs();
  }

  /// Add a session-only detection map (not persisted).
  void addSessionDetection(Map<String, dynamic> detection) {
    _sessionDetections.add(detection);
  }

  /// Clear only session detections.
  void clearSession() {
    _sessionDetections.clear();
  }

  /// Clear persisted detections and session detections.
  void clearAll() {
    state = [];
    _sessionDetections.clear();
    totalCount = 0;
    saveToPrefs();
  }

  /// Persist current `state` to SharedPreferences as a JSON array.
  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.map((e) => e.toJson()).toList();
      await prefs.setString(_kReportsKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Load cached detections from SharedPreferences into `state` and update `totalCount`.
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kReportsKey);
      if (raw == null || raw.isEmpty) {
        totalCount = 0;
        return;
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      final parsed = <PotholeDetection>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            parsed.add(PotholeDetection.fromJson(item));
          } catch (_) {}
        }
      }
      if (parsed.isNotEmpty) state = parsed;
      totalCount = state.length;
    } catch (_) {
      totalCount = state.length;
    }
  }
}

final potholeProvider =
    StateNotifierProvider<PotholeNotifier, List<PotholeDetection>>(
      (ref) => PotholeNotifier(),
    );

/// Expose the four requested values via simple Providers
final totalDetectionsProvider = Provider<int>((ref) {
  final notifier = ref.watch(potholeProvider.notifier);
  return notifier.totalCount;
});

final sessionDetectionsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final notifier = ref.watch(potholeProvider.notifier);
  return notifier.sessionDetections;
});

final sessionCountProvider = Provider<int>((ref) {
  final notifier = ref.watch(potholeProvider.notifier);
  return notifier.sessionCount;
});

// Backwards-compatible session-level notifier (used by existing screens)
class SessionPotholesNotifier
    extends StateNotifier<List<Map<String, dynamic>>> {
  SessionPotholesNotifier() : super([]);

  void add(Map<String, dynamic> detection) {
    state = [...state, detection];
  }

  void clear() {
    state = [];
  }

  int get count => state.length;
}

final sessionPotholesProvider =
    StateNotifierProvider<SessionPotholesNotifier, List<Map<String, dynamic>>>(
      (ref) => SessionPotholesNotifier(),
    );

final sessionPotholesCountProvider = Provider<int>(
  (ref) => ref.watch(sessionPotholesProvider).length,
);
