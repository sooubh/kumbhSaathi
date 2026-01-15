import 'package:latlong2/latlong.dart';

/// User location model for Firestore realtime tracking
class UserLocation {
  final String userId;
  final String userName;
  final LatLng position;
  final double accuracy;
  final DateTime timestamp;
  final bool isSharing;
  final String? status; // "active", "moving", "stationary", "offline"

  UserLocation({
    required this.userId,
    required this.userName,
    required this.position,
    required this.accuracy,
    required this.timestamp,
    this.isSharing = true,
    this.status,
  });

  /// Check if location is stale (older than 5 minutes)
  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes > 5;
  }

  /// Check if location is recent (within last minute)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes < 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'isSharing': isSharing,
      'status': status ?? 'active',
    };
  }

  /// For Firestore - use Timestamp instead of ISO string
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': accuracy,
      'timestamp': timestamp, // Firestore will convert to Timestamp
      'isSharing': isSharing,
      'status': status ?? 'active',
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : (json['timestamp'] as DateTime), // Handle Timestamp from Firestore
      isSharing: json['isSharing'] as bool? ?? true,
      status: json['status'] as String?,
    );
  }

  /// From Firestore document
  factory UserLocation.fromFirestore(Map<String, dynamic> data) {
    // Handle Firestore Timestamp
    DateTime timestamp;
    if (data['timestamp'] is String) {
      timestamp = DateTime.parse(data['timestamp'] as String);
    } else {
      // Assuming it's a Firestore Timestamp object
      final ts = data['timestamp'];
      timestamp = (ts as dynamic).toDate() as DateTime;
    }

    return UserLocation(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      position: LatLng(
        (data['latitude'] as num).toDouble(),
        (data['longitude'] as num).toDouble(),
      ),
      accuracy: (data['accuracy'] as num).toDouble(),
      timestamp: timestamp,
      isSharing: data['isSharing'] as bool? ?? true,
      status: data['status'] as String?,
    );
  }

  UserLocation copyWith({
    String? userId,
    String? userName,
    LatLng? position,
    double? accuracy,
    DateTime? timestamp,
    bool? isSharing,
    String? status,
  }) {
    return UserLocation(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      position: position ?? this.position,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isSharing: isSharing ?? this.isSharing,
      status: status ?? this.status,
    );
  }
}
