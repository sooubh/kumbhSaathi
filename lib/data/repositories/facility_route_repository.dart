import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility_route.dart';
import '../../core/services/firebase_service.dart';

/// Repository for facility routes data
class FacilityRouteRepository {
  final _firestore = FirebaseService.firestore;

  /// Save a newly recorded route
  Future<String> saveRoute(FacilityRoute route) async {
    try {
      final data = route.toJson();
      data.remove('id');
      data['status'] = 'pending';
      data['recordedAt'] = Timestamp.now();

      final docRef = await _firestore
          .collection(FirestoreCollections.facilityRoutes)
          .add(data);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save route: $e');
    }
  }

  /// Get approved routes for a specific facility
  Stream<List<FacilityRoute>> getApprovedRoutesForFacility(String facilityId) {
    return _firestore
        .collection(FirestoreCollections.facilityRoutes)
        .where('facilityId', isEqualTo: facilityId)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => FacilityRoute.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  /// Get pending routes for admin approval
  Stream<List<FacilityRoute>> getPendingRoutes() {
    return _firestore
        .collection(FirestoreCollections.facilityRoutes)
        .where('status', isEqualTo: 'pending')
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => FacilityRoute.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  /// Get routes submitted by a specific user
  Stream<List<FacilityRoute>> getMyRoutes(String userId) {
    return _firestore
        .collection(FirestoreCollections.facilityRoutes)
        .where('userId', isEqualTo: userId)
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => FacilityRoute.fromJson({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  /// Approve a route
  Future<void> approveRoute(String routeId, String reviewerId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilityRoutes)
          .doc(routeId)
          .update({
            'status': 'approved',
            'reviewedBy': reviewerId,
            'reviewedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to approve route: $e');
    }
  }

  /// Reject a route with reason
  Future<void> rejectRoute(
    String routeId,
    String reviewerId,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilityRoutes)
          .doc(routeId)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'reviewedBy': reviewerId,
            'reviewedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to reject route: $e');
    }
  }

  /// Delete a route
  Future<void> deleteRoute(String routeId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilityRoutes)
          .doc(routeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete route: $e');
    }
  }
}
