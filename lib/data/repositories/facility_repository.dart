import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/facility.dart';
import '../models/verification_request.dart';
import '../../core/services/firebase_service.dart';

/// Repository for facilities data
class FacilityRepository {
  final _firestore = FirebaseService.firestore;
  final _storage = FirebaseStorage.instance;
  
  /// Upload image to storage and return URL
  Future<String> uploadFacilityImage(File file, String name) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$name.jpg';
      final ref = _storage.ref().child('facilities/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

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
      final now = DateTime.now();
      final data = facility.toJson();
      data.remove('id');
      data['status'] = 'pending';
      data['submittedAt'] = Timestamp.fromDate(now);
      data['lastVerifiedAt'] = Timestamp.fromDate(now);
      data['nextVerificationDue'] = Timestamp.fromDate(now.add(const Duration(days: 7)));

      await _firestore.collection(FirestoreCollections.facilities).add(data);
    } catch (e) {
      throw Exception('Failed to add facility: $e');
    }
  }

  /// Verify a facility to extend its life by 7 days
  Future<void> verifyFacility(String id) async {
    try {
      final now = DateTime.now();
      await _firestore
          .collection(FirestoreCollections.facilities)
          .doc(id)
          .update({
            'lastVerifiedAt': Timestamp.fromDate(now),
            'nextVerificationDue': Timestamp.fromDate(now.add(const Duration(days: 7))),
          });
    } catch (e) {
      throw Exception('Failed to verify facility: $e');
    }
  }

  /// Cleanup facilities that haven't been verified for 7 days
  Future<void> cleanupExpiredFacilities() async {
    try {
      final now = Timestamp.now();
      final snapshot = await _firestore
          .collection(FirestoreCollections.facilities)
          .where('nextVerificationDue', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      // Silently fail cleanup errors
    }
  }

  /// Upload verification image to storage
  Future<String> uploadVerificationImage(File file, String facilityId) async {
    try {
      final fileName = 'verification_${DateTime.now().millisecondsSinceEpoch}_$facilityId.jpg';
      final ref = _storage.ref().child('verifications/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload verification image: $e');
    }
  }

  /// Submit a verification request for admin review
  Future<void> submitVerificationRequest(VerificationRequest request) async {
    try {
      final data = request.toJson();
      await _firestore.collection(FirestoreCollections.verificationRequests).add(data);
    } catch (e) {
      throw Exception('Failed to submit verification request: $e');
    }
  }

  /// Check if a facility has a pending verification request
  Stream<bool> hasPendingVerification(String facilityId, String userId) {
    return _firestore
        .collection(FirestoreCollections.verificationRequests)
        .where('facilityId', isEqualTo: facilityId)
        .where('submittedBy', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Approve a facility
  Future<void> approveFacility(String id, String reviewerId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilities)
          .doc(id)
          .update({
            'status': 'approved',
            'reviewedBy': reviewerId,
            'reviewedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to approve facility: $e');
    }
  }

  /// Reject a facility with reason
  Future<void> rejectFacility(
    String id,
    String reviewerId,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(FirestoreCollections.facilities)
          .doc(id)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'reviewedBy': reviewerId,
            'reviewedAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to reject facility: $e');
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

  /// Get facilities submitted by a specific user
  Stream<List<Facility>> getMyFacilities(String userId) {
    return _firestore
        .collection(FirestoreCollections.facilities)
        .where('submittedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final facilities = snapshot.docs.map((doc) {
            final data = doc.data();
            return Facility.fromJson({...data, 'id': doc.id});
          }).toList();
          // Sort by submission date (newest first)
          facilities.sort(
            (a, b) => (b.submittedAt ?? DateTime.now()).compareTo(
              a.submittedAt ?? DateTime.now(),
            ),
          );
          return facilities;
        });
  }

  /// Seed initial facilities data
  Future<void> seedFacilities() async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore.collection(FirestoreCollections.facilities);

      // Check if data already exists
      // final snapshot = await collection.limit(1).get();
      // if (snapshot.docs.isNotEmpty) return;

      final facilities = [
        {
          'name': 'Charging Point Zone A',
          'nameHindi': 'चार्जिंग पॉइंट जोन A',
          'type': 'chargingPoint',
          'latitude': 20.0075,
          'longitude': 73.7905,
          'distanceMeters': 250,
          'walkTimeMinutes': 4,
          'isOpen': true,
          'status': 'approved',
        },
        {
          'name': 'Drinking Water Booth 1',
          'nameHindi': 'पीने के पानी का बूथ 1',
          'type': 'drinkingWater',
          'latitude': 20.0068,
          'longitude': 73.7888,
          'distanceMeters': 120,
          'walkTimeMinutes': 2,
          'isOpen': true,
          'status': 'approved',
        },
        {
          'name': 'Food & Prasad Center',
          'nameHindi': 'भोजन और प्रसाद केंद्र',
          'type': 'food',
          'latitude': 20.0072,
          'longitude': 73.7898,
          'distanceMeters': 300,
          'walkTimeMinutes': 5,
          'isOpen': true,
          'phone': '+91-9876543210',
          'status': 'approved',
        },
        {
          'name': 'Help Desk Near Main Gate',
          'nameHindi': 'मुख्य द्वार के पास सहायता केंद्र',
          'type': 'helpDesk',
          'latitude': 20.0059,
          'longitude': 73.7885,
          'distanceMeters': 90,
          'walkTimeMinutes': 1,
          'isOpen': true,
          'status': 'approved',
        },
        {
          'name': 'Parking Area P1',
          'nameHindi': 'पार्किंग क्षेत्र P1',
          'type': 'parking',
          'latitude': 20.0080,
          'longitude': 73.7912,
          'distanceMeters': 600,
          'walkTimeMinutes': 9,
          'isOpen': true,
          'status': 'approved',
        },
        {
          'name': 'Hotel Ganga View',
          'nameHindi': 'होटल गंगा व्यू',
          'type': 'hotel',
          'latitude': 20.0092,
          'longitude': 73.7920,
          'distanceMeters': 1200,
          'walkTimeMinutes': 18,
          'isOpen': true,
          'phone': '+91-9123456789',
          'status': 'approved',
        },
        {
          'name': 'Temporary Police Checkpost',
          'nameHindi': 'अस्थायी पुलिस चौकी',
          'type': 'police',
          'latitude': 20.0061,
          'longitude': 73.7899,
          'distanceMeters': 180,
          'walkTimeMinutes': 3,
          'isOpen': true,
          'phone': '112',
          'status': 'approved',
        },
        {
          'name': 'Public Washroom Block 5',
          'nameHindi': 'पब्लिक वॉशरूम ब्लॉक 5',
          'type': 'washroom',
          'latitude': 20.0057,
          'longitude': 73.7889,
          'distanceMeters': 70,
          'walkTimeMinutes': 1,
          'isOpen': true,
          'status': 'approved',
        },
        {
          'name': 'Lost & Found Center',
          'nameHindi': 'खोया-पाया केंद्र',
          'type': 'other',
          'latitude': 20.0069,
          'longitude': 73.7903,
          'distanceMeters': 220,
          'walkTimeMinutes': 4,
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
