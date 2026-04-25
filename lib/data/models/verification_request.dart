import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a verification request sent by a user to verify an existing facility
class VerificationRequest {
  final String id;
  final String facilityId;
  final String facilityName;
  final String submittedBy;
  final DateTime submittedAt;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String status; // 'pending', 'approved', 'rejected'

  VerificationRequest({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.submittedBy,
    required this.submittedAt,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.status = 'pending',
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'] as String,
      facilityId: json['facilityId'] as String,
      facilityName: json['facilityName'] as String,
      submittedBy: json['submittedBy'] as String,
      submittedAt: json['submittedAt'] != null 
          ? (json['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facilityId': facilityId,
      'facilityName': facilityName,
      'submittedBy': submittedBy,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'status': status,
    };
  }
}
