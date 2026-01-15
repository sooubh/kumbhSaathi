import 'package:latlong2/latlong.dart';

/// Custom walking path created by users
class CustomWalkingPath {
  final String id;
  final String name;
  final String description;
  final String startLocationId; // Ghat or facility ID
  final String endLocationId; // Ghat or facility ID
  final String startLocationName;
  final String endLocationName;
  final List<LatLng> waypoints; // Recorded path points
  final double distanceMeters;
  final int durationSeconds;
  final String createdBy; // User ID
  final String createdByName;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final bool isWalkingOnly; // True if cars/bikes cannot use
  final bool isVerified; // Verified by admin
  final List<String> tags; // e.g., "shortcut", "scenic", "shaded", "stairs"
  final String? photoUrl; // Optional path photo

  CustomWalkingPath({
    required this.id,
    required this.name,
    required this.description,
    required this.startLocationId,
    required this.endLocationId,
    required this.startLocationName,
    required this.endLocationName,
    required this.waypoints,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isWalkingOnly = true,
    this.isVerified = false,
    this.tags = const [],
    this.photoUrl,
  });

  /// Rating score (upvotes - downvotes)
  int get rating => upvotes - downvotes;

  /// Check if path is highly rated (score >= 5)
  bool get isHighlyRated => rating >= 5;

  /// Formatted distance
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)}km';
    }
  }

  /// Formatted duration
  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    return '${minutes}min';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startLocationId': startLocationId,
      'endLocationId': endLocationId,
      'startLocationName': startLocationName,
      'endLocationName': endLocationName,
      'waypoints': waypoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isWalkingOnly': isWalkingOnly,
      'isVerified': isVerified,
      'tags': tags,
      'photoUrl': photoUrl,
    };
  }

  factory CustomWalkingPath.fromJson(Map<String, dynamic> json) {
    return CustomWalkingPath(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startLocationId: json['startLocationId'] as String,
      endLocationId: json['endLocationId'] as String,
      startLocationName: json['startLocationName'] as String,
      endLocationName: json['endLocationName'] as String,
      waypoints: (json['waypoints'] as List)
          .map((w) => LatLng(w['lat'] as double, w['lng'] as double))
          .toList(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      isWalkingOnly: json['isWalkingOnly'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      tags: (json['tags'] as List?)?.map((t) => t as String).toList() ?? [],
      photoUrl: json['photoUrl'] as String?,
    );
  }

  CustomWalkingPath copyWith({
    String? id,
    String? name,
    String? description,
    int? upvotes,
    int? downvotes,
    bool? isVerified,
  }) {
    return CustomWalkingPath(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startLocationId: startLocationId,
      endLocationId: endLocationId,
      startLocationName: startLocationName,
      endLocationName: endLocationName,
      waypoints: waypoints,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isWalkingOnly: isWalkingOnly,
      isVerified: isVerified ?? this.isVerified,
      tags: tags,
      photoUrl: photoUrl,
    );
  }
}
