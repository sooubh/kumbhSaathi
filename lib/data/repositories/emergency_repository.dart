import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';

/// Emergency alert model
class EmergencyAlert {
  final String id;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final String locationDescription;
  final DateTime timestamp;
  final EmergencyType type;
  final bool isResolved;
  final String? resolvedBy;

  EmergencyAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.locationDescription,
    required this.timestamp,
    this.type = EmergencyType.sos,
    this.isResolved = false,
    this.resolvedBy,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationDescription: json['locationDescription'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      type: EmergencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyType.sos,
      ),
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedBy: json['resolvedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'locationDescription': locationDescription,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      'isResolved': isResolved,
      'resolvedBy': resolvedBy,
    };
  }
}

enum EmergencyType { sos, medical, lost, fire, other }

/// Repository for emergency alerts
class EmergencyRepository {
  final CollectionReference<Map<String, dynamic>> _collection = FirebaseService
      .firestore
      .collection(FirestoreCollections.emergencyAlerts);

  /// Send SOS alert
  Future<String> sendSOSAlert({
    required String userId,
    required String userName,
    required double latitude,
    required double longitude,
    required String locationDescription,
    EmergencyType type = EmergencyType.sos,
  }) async {
    final docRef = await _collection.add({
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'locationDescription': locationDescription,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type.name,
      'isResolved': false,
    });
    return docRef.id;
  }

  /// Get active alerts stream
  Stream<List<EmergencyAlert>> getActiveAlertsStream() {
    return _collection
        .where('isResolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => EmergencyAlert.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Get user's alerts
  Stream<List<EmergencyAlert>> getUserAlertsStream(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => EmergencyAlert.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList(),
        );
  }

  /// Mark alert as resolved
  Future<void> resolveAlert(String alertId, String resolvedBy) async {
    await _collection.doc(alertId).update({
      'isResolved': true,
      'resolvedBy': resolvedBy,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel SOS alert
  Future<void> cancelAlert(String alertId) async {
    await _collection.doc(alertId).delete();
  }
}
