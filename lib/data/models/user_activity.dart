import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { image, voice, emergency, sos, other }

class UserActivity {
  final String id;
  final String userId;
  final ActivityType type;
  final String? url;
  final String? description;
  final DateTime timestamp;

  UserActivity({
    required this.id,
    required this.userId,
    required this.type,
    this.url,
    this.description,
    required this.timestamp,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json, String id) {
    return UserActivity(
      id: id,
      userId: json['userId'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.other,
      ),
      url: json['url'] as String?,
      description: json['description'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.name,
      'url': url,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
