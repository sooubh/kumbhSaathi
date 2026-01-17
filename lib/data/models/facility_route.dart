import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a user-contributed route to a facility
class FacilityRoute {
  final String id;
  final String facilityId;
  final String userId;
  final String userName;
  final List<RoutePoint> pathPoints;
  final double distanceMeters;
  final int durationMinutes;
  final DateTime recordedAt;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  FacilityRoute({
    required this.id,
    required this.facilityId,
    required this.userId,
    required this.userName,
    required this.pathPoints,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.recordedAt,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory FacilityRoute.fromJson(Map<String, dynamic> json) {
    return FacilityRoute(
      id: json['id'] as String,
      facilityId: json['facilityId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      pathPoints: (json['pathPoints'] as List)
          .map((p) => RoutePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      recordedAt: (json['recordedAt'] as Timestamp).toDate(),
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? (json['reviewedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facilityId': facilityId,
      'userId': userId,
      'userName': userName,
      'pathPoints': pathPoints.map((p) => p.toJson()).toList(),
      'distanceMeters': distanceMeters,
      'durationMinutes': durationMinutes,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }
}

/// Single GPS point in a route
class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
