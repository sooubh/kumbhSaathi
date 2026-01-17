import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ghat.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';
import 'package:logger/logger.dart';

/// Repository for ghats data
class GhatRepository {
  final CollectionReference<Map<String, dynamic>> _collection = FirebaseService
      .firestore
      .collection(FirestoreCollections.ghats);
  final _logger = Logger();

  /// Get all ghats
  Stream<List<Ghat>> getGhatsStream() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Ghat.fromJson({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  /// Get ghats sorted by distance
  Future<List<Ghat>> getNearbyGhats(double lat, double lng, int limit) async {
    // Note: For production, you'd use GeoFirestore for geospatial queries
    final snapshot = await _collection.limit(limit).get();
    return snapshot.docs
        .map((doc) => Ghat.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Get ghat by ID
  Future<Ghat?> getGhatById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return Ghat.fromJson({...doc.data()!, 'id': doc.id});
    }
    return null;
  }

  /// Update crowd level (admin only)
  Future<void> updateCrowdLevel(
    String id,
    CrowdLevel level, {
    bool shouldNotify = false,
    String? customMessage,
  }) async {
    // Get current ghat data for notification if needed
    Ghat? ghat;
    if (shouldNotify) {
      ghat = await getGhatById(id);
    }

    await _collection.doc(id).update({
      'crowdLevel': level.name,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Send notification if enabled
    if (shouldNotify && ghat != null) {
      try {
        await NotificationService().sendCrowdLevelNotification(
          ghatName: ghat.name,
          oldLevel: ghat.crowdLevel.name,
          newLevel: level.name,
          customMessage: customMessage,
        );
      } catch (e) {
        _logger.e('Error sending crowd notification: $e');
        // Don't fail the update if notification fails
      }
    }
  }

  /// Get ghats by crowd level
  Stream<List<Ghat>> getGhatsByCrowdLevel(CrowdLevel level) {
    return _collection
        .where('crowdLevel', isEqualTo: level.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Ghat.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// Add new ghat
  Future<String> addGhat(Ghat ghat) async {
    final docRef = await _collection.add(ghat.toJson());
    return docRef.id;
  }

  /// Delete ghat
  Future<void> deleteGhat(String id) async {
    await _collection.doc(id).delete();
  }

  /// Seed initial ghat data (for development)
  Future<void> seedGhats() async {
    final ghats = [
      {
        'name': 'Triveni Sangam',
        'nameHindi': 'त्रिवेणी संगम',
        'description':
            'Main confluence point of Godavari, Vaitarna and Panchganga rivers',
        'latitude': 20.0063,
        'longitude': 73.7897,
        'distanceKm': 0.0,
        'walkTimeMinutes': 0,
        'crowdLevel': 'high',
        'bestTimeStart': '4:00 AM',
        'bestTimeEnd': '6:00 AM',
        'isGoodForBathing': true,
        'facilities': ['parking', 'washroom', 'changing_room'],
      },
      {
        'name': 'Ramkund',
        'nameHindi': 'रामकुंड',
        'description': 'Most sacred bathing ghat where Lord Rama bathed',
        'latitude': 20.0090,
        'longitude': 73.7920,
        'distanceKm': 0.5,
        'walkTimeMinutes': 7,
        'crowdLevel': 'medium',
        'bestTimeStart': '5:00 AM',
        'bestTimeEnd': '7:00 AM',
        'isGoodForBathing': true,
        'facilities': ['parking', 'washroom', 'medical'],
      },
      {
        'name': 'Panchvati',
        'nameHindi': 'पंचवटी',
        'description': 'Where Lord Rama, Sita and Lakshmana lived during exile',
        'latitude': 20.0050,
        'longitude': 73.7850,
        'distanceKm': 1.2,
        'walkTimeMinutes': 15,
        'crowdLevel': 'low',
        'isGoodForBathing': true,
        'facilities': ['parking', 'temple'],
      },
      {
        'name': 'Kapila Godavari',
        'nameHindi': 'कपिला गोदावरी',
        'description': 'Confluence of Kapila and Godavari rivers',
        'latitude': 20.0120,
        'longitude': 73.7880,
        'distanceKm': 0.8,
        'walkTimeMinutes': 10,
        'crowdLevel': 'low',
        'bestTimeStart': '6:00 AM',
        'bestTimeEnd': '8:00 AM',
        'isGoodForBathing': true,
        'facilities': ['washroom'],
      },
    ];

    final batch = FirebaseService.firestore.batch();
    for (final ghat in ghats) {
      batch.set(_collection.doc(), ghat);
    }
    await batch.commit();
  }
}
