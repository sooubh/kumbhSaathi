import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kumbh_update.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';

/// Repository for Kumbh Mela updates
class KumbhUpdateRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseService.firestore.collection('kumbh_updates');

  /// Create a new Kumbh update (Admin only)
  Future<String> createUpdate(KumbhUpdate update) async {
    final docRef = await _collection.add(update.toJson());

    // Send notification to all users
    await NotificationService().sendKumbhUpdateNotification(
      title: update.title,
      body: update.description,
      eventId: docRef.id,
    );

    return docRef.id;
  }

  /// Get all Kumbh updates stream
  Stream<List<KumbhUpdate>> getUpdatesStream() {
    return _collection
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KumbhUpdate.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Get upcoming events (future dates only)
  Stream<List<KumbhUpdate>> getUpcomingEvents() {
    return _collection
        .where('eventDate', isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
        .orderBy('eventDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KumbhUpdate.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Get important announcements
  Stream<List<KumbhUpdate>> getImportantAnnouncements() {
    return _collection
        .where('isImportant', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KumbhUpdate.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Get updates by category
  Stream<List<KumbhUpdate>> getUpdatesByCategory(String category) {
    return _collection
        .where('category', isEqualTo: category)
        .orderBy('event Date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => KumbhUpdate.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Delete update (Admin only)
  Future<void> deleteUpdate(String id) async {
    await _collection.doc(id).delete();
  }

  /// Update an existing update (Admin only)
  Future<void> updateUpdate(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update(data);
  }
}
