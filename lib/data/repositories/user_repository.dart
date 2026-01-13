import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../../core/services/firebase_service.dart';

/// Repository for user profile data
class UserRepository {
  final CollectionReference<Map<String, dynamic>> _collection = FirebaseService
      .firestore
      .collection(FirestoreCollections.users);

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return null;
    return getUserById(userId);
  }

  /// Get user by ID
  Future<UserProfile?> getUserById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return UserProfile.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  /// Create or update user profile
  Future<void> saveProfile(UserProfile profile) async {
    await _collection
        .doc(profile.id)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  /// Update specific fields
  Future<void> updateProfile(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }

  /// Add emergency contact
  Future<void> addEmergencyContact(
    String userId,
    EmergencyContact contact,
  ) async {
    await _collection.doc(userId).update({
      'emergencyContacts': FieldValue.arrayUnion([contact.toJson()]),
    });
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact(
    String userId,
    EmergencyContact contact,
  ) async {
    await _collection.doc(userId).update({
      'emergencyContacts': FieldValue.arrayRemove([contact.toJson()]),
    });
  }

  /// Update medical info
  Future<void> updateMedicalInfo(String userId, MedicalInfo medicalInfo) async {
    await _collection.doc(userId).update({'medicalInfo': medicalInfo.toJson()});
  }

  /// Stream user profile changes
  Stream<UserProfile?> getUserProfileStream(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }
}
