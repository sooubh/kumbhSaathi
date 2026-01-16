import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facility.dart';
import '../../core/services/firebase_service.dart';

/// Repository for facilities data
class FacilityRepository {
  final _firestore = FirebaseService.firestore;

  /// Get stream of approved facilities (for users)
  Stream<List<Facility>> getFacilities() {
    return _firestore
        .collection(FirestoreCollections.facilities)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Facility.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  /// Get stream of pending facilities (for admin)
  Stream<List<Facility>> getPendingFacilities() {
    return _firestore
        .collection(FirestoreCollections.facilities)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Facility.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  /// Get facilities by type (approved only)
  Stream<List<Facility>> getFacilitiesByType(FacilityType type) {
    return _firestore
        .collection(FirestoreCollections.facilities)
        .where('status', isEqualTo: 'approved')
        .where('type', isEqualTo: type.name)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Facility.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  /// Get nearby facilities (approved only)
  Future<List<Facility>> getNearbyFacilities(
    double lat,
    double lng,
    int limit,
  ) async {
    // Note: For production, use GeoFirestore.
    // This is a basic implementation fetching all approved and filtering.
    // Optimization: In real app, restrict by lat/lng range queries.
    final snapshot = await _firestore
        .collection(FirestoreCollections.facilities)
        .where('status', isEqualTo: 'approved')
        .limit(limit * 2) // Fetch more to filter by distance locally if needed
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Facility.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  /// Add a new facility (pending by default)
  Future<void> addFacility(Facility facility) async {
    try {
      final data = facility.toJson();
      data.remove('id');
      data['status'] = 'pending';
      data['submittedAt'] = Timestamp.now();

      await _firestore.collection(FirestoreCollections.facilities).add(data);
    } catch (e) {
      throw Exception('Failed to add facility: $e');
    }
  }

  /// Approve a facility
  Future<void> approveFacility(String id) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilities)
          .doc(id)
          .update({'status': 'approved'});
    } catch (e) {
      throw Exception('Failed to approve facility: $e');
    }
  }

  /// Reject/Delete a facility
  Future<void> deleteFacility(String id) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilities)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete facility: $e');
    }
  }

  /// Seed initial facilities data
  Future<void> seedFacilities() async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection(FirestoreCollections.facilities);

      // Check if data already exists
      final snapshot = await collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final facilities = [
        {
          'name': 'Medical Camp Sector 4',
          'nameHindi': 'मेडिकल कैंप सेक्टर 4',
          'type': 'medical',
          'latitude': 20.0070,
          'longitude': 73.7900,
          'distanceMeters': 200,
          'walkTimeMinutes': 3,
          'isOpen': true,
          'phone': '+91-1234567890',
          'status': 'approved',
        },
        {
          'name': 'Police Station Gate 3',
          'nameHindi': 'पुलिस स्टेशन गेट 3',
          'type': 'police',
          'latitude': 20.0065,
          'longitude': 73.7890,
          'distanceMeters': 150,
          'walkTimeMinutes': 2,
          'isOpen': true,
          'phone': '100',
          'status': 'approved',
        },
        {
          'name': 'Public Washroom Block 2',
          'nameHindi': 'पब्लिक वॉशरूम ब्लॉक 2',
          'type': 'washroom',
          'latitude': 20.0062,
          'longitude': 73.7892,
          'distanceMeters': 80,
          'walkTimeMinutes': 1,
          'isOpen': true,
          'status': 'approved',
        },
      ];

      for (final data in facilities) {
        final docRef = collection.doc();
        batch.set(docRef, data);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to seed facilities: $e');
    }
  }
}
