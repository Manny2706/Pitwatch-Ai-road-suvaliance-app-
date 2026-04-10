// Model for storing pothole detections
enum PotholeStatus { reported, underRepair, fixed, pending, unknown }

enum Severity { low, medium, high, unknown }

String _statusToString(PotholeStatus s) {
  switch (s) {
    case PotholeStatus.reported:
      return 'reported';
    case PotholeStatus.underRepair:
      return 'underRepair';
    case PotholeStatus.fixed:
      return 'fixed';
    case PotholeStatus.pending:
      return 'pending';
    case PotholeStatus.unknown:
      return 'unknown';
  }
}

PotholeStatus _statusFromString(String? s) {
  if (s == null) return PotholeStatus.unknown;
  final lower = s.toLowerCase();
  if (lower == 'reported') return PotholeStatus.reported;
  if (lower == 'underrepair' ||
      lower == 'under_repair' ||
      lower == 'underRepair')
    return PotholeStatus.underRepair;
  if (lower == 'fixed') return PotholeStatus.fixed;
  if (lower == 'pending') return PotholeStatus.pending;
  return PotholeStatus.unknown;
}

String severityToString(Severity s) {
  switch (s) {
    case Severity.low:
      return 'low';
    case Severity.medium:
      return 'medium';
    case Severity.high:
      return 'high';
    case Severity.unknown:
    default:
      return 'unknown';
  }
}

Severity severityFromString(String? s) {
  if (s == null) return Severity.unknown;
  final lower = s.toLowerCase();
  if (lower == 'low') return Severity.low;
  if (lower == 'medium') return Severity.medium;
  if (lower == 'high') return Severity.high;
  return Severity.unknown;
}

class PotholeDetection {
  final int id;
  final String title;
  final String description;
  final Severity severity;
  final PotholeStatus status;
  final double latitude;
  final double longitude;
  final String createdAt;

  PotholeDetection({
    required this.id,
    required this.title,
    required this.description,
    this.severity = Severity.unknown,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': _statusToString(status),
    'severity': severityToString(severity),
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt,
  };

  factory PotholeDetection.fromJson(Map<String, dynamic> json) =>
      PotholeDetection(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        severity: severityFromString(json['severity'] as String?),
        status: _statusFromString(json['status'] as String?),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        createdAt: json['created_at'] as String,
      );

  /// Try to create a PotholeDetection from a loosely-typed map.
  /// Returns null if required fields are missing or cannot be parsed.
  static PotholeDetection? tryFromJson(Map<String, dynamic> json) {
    try {
      // id
      dynamic idRaw = json['id'] ?? json['identifier'];
      int id;
      if (idRaw is int) {
        id = idRaw;
      } else if (idRaw is num) {
        id = idRaw.toInt();
      } else if (idRaw is String) {
        id = int.tryParse(idRaw) ?? DateTime.now().millisecondsSinceEpoch;
      } else {
        return null;
      }

      // title / fallback keys
      final titleRaw = json['title'] ?? json['name'] ?? json['label'];
      final title = titleRaw?.toString();
      if (title == null || title.trim().isEmpty) return null;

      final description = (json['description'] ?? json['desc'] ?? '')
          .toString();

      // severity and status
      final severity = severityFromString(
        (json['severity'] ?? json['severity_level'])?.toString(),
      );
      final status = _statusFromString(
        (json['status'] ?? json['state'])?.toString(),
      );

      // lat / lon (accept strings or numbers)
      dynamic latRaw = json['latitude'] ?? json['lat'];
      dynamic lonRaw = json['longitude'] ?? json['lon'] ?? json['lng'];
      if (latRaw == null || lonRaw == null) return null;
      double latitude;
      double longitude;
      if (latRaw is num)
        latitude = latRaw.toDouble();
      else if (latRaw is String) {
        latitude = double.tryParse(latRaw) ?? double.nan;
      } else {
        return null;
      }
      if (lonRaw is num)
        longitude = lonRaw.toDouble();
      else if (lonRaw is String) {
        longitude = double.tryParse(lonRaw) ?? double.nan;
      } else {
        return null;
      }
      if (latitude.isNaN || longitude.isNaN) return null;

      final createdAt =
          (json['created_at'] ??
                  json['createdAt'] ??
                  DateTime.now().toIso8601String())
              .toString();

      return PotholeDetection(
        id: id,
        title: title,
        description: description,
        severity: severity,
        status: status,
        latitude: latitude,
        longitude: longitude,
        createdAt: createdAt,
      );
    } catch (_) {
      return null;
    }
  }
}

// UI-friendly status and mapper
enum IssueStatus { reported, underRepair, fixed }

IssueStatus mapPotholeStatus(PotholeStatus s) {
  switch (s) {
    case PotholeStatus.fixed:
      return IssueStatus.fixed;
    case PotholeStatus.underRepair:
      return IssueStatus.underRepair;
    case PotholeStatus.reported:
    case PotholeStatus.pending:
    case PotholeStatus.unknown:
    default:
      return IssueStatus.reported;
  }
}
