import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_person.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';

/// Repository for lost persons data
class LostPersonRepository {
  final CollectionReference<Map<String, dynamic>> _collection = FirebaseService
      .firestore
      .collection(FirestoreCollections.lostPersons);

  /// Report a new lost person
  Future<String> reportLostPerson(LostPerson person) async {
    final docRef = await _collection.add(person.toJson());
    
    // Send notification to all users
    await NotificationService().sendLostPersonNotification(
      personId: docRef.id,
      personName: person.name,
      description: '${person.gender}, ${person.age} years old. Last seen at ${person.lastSeenLocation}',
      photoUrl: person.photoUrl,
    );
    
    return docRef.id;
  }

  /// Get all lost persons
  Stream<List<LostPerson>> getLostPersonsStream() {
    return _collection
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostPerson.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Get lost person by ID
  Future<LostPerson?> getLostPersonById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return LostPerson.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  /// Update lost person status
  Future<void> updateStatus(String id, LostPersonStatus status) async {
    await _collection.doc(id).update({'status': status.name});
  }

  /// Mark as found
  Future<void> markAsFound(String id) async {
    await updateStatus(id, LostPersonStatus.found);
  }

  /// Delete lost person report
  Future<void> deleteReport(String id) async {
    await _collection.doc(id).delete();
  }

  /// Search lost persons by name
  Stream<List<LostPerson>> searchByName(String query) {
    return _collection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostPerson.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}
