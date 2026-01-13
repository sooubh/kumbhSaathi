import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../models/user_activity.dart';

class ActivityRepository {
  final _firestore = FirebaseService.firestore;

  CollectionReference get _users =>
      _firestore.collection(FirestoreCollections.users);

  /// Add a new activity log
  Future<void> addActivity(UserActivity activity) async {
    try {
      await _users
          .doc(activity.userId)
          .collection('activities')
          .add(activity.toJson());
    } catch (e) {
      throw Exception('Failed to log activity: $e');
    }
  }

  /// Get simplified stream of activities for a user
  Stream<List<UserActivity>> getUserActivities(String userId) {
    return _users
        .doc(userId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserActivity.fromJson(doc.data(), doc.id);
          }).toList();
        });
  }
}
