import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/user_location_model.dart';
import 'map_service.dart';

/// Service for managing user locations in Firestore
class FirestoreLocationService {
  static final FirestoreLocationService _instance =
      FirestoreLocationService._internal();
  factory FirestoreLocationService() => _instance;
  FirestoreLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapService _mapService = MapService();

  static const String _collectionName = 'user_locations';

  /// Update user's current location in Firestore
  Future<void> updateUserLocation(UserLocation location) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(location.userId)
          .set(location.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user location: $e');
    }
  }

  /// Stream a specific user's location
  Stream<UserLocation?> streamUserLocation(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserLocation.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
      );
    });
  }

  /// Get a specific user's current location (one-time fetch)
  Future<UserLocation?> getUserLocation(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (!doc.exists) return null;

      return UserLocation.fromFirestore(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get user location: $e');
    }
  }

  /// Stream nearby users within a radius
  /// Note: For production, use Firestore geoqueries or GeoFlutterFire
  /// This is a simplified version that fetches all and filters client-side
  Stream<List<UserLocation>> streamNearbyUsers({
    required LatLng center,
    required double radiusMeters,
    String? excludeUserId,
  }) {
    return _firestore
        .collection(_collectionName)
        .where('isSharing', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final allLocations = snapshot.docs
          .map((doc) =>
              UserLocation.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by radius and exclude specific user
      return allLocations.where((location) {
        if (excludeUserId != null && location.userId == excludeUserId) {
          return false;
        }

        final distance = _mapService.calculateDistance(
          center,
          location.position,
        );

        return distance <= radiusMeters && !location.isStale;
      }).toList();
    });
  }

  /// Get nearby users (one-time fetch)
  Future<List<UserLocation>> getNearbyUsers({
    required LatLng center,
    required double radiusMeters,
    String? excludeUserId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isSharing', isEqualTo: true)
          .get();

      final allLocations = snapshot.docs
          .map((doc) =>
              UserLocation.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by radius and exclude specific user
      return allLocations.where((location) {
        if (excludeUserId != null && location.userId == excludeUserId) {
          return false;
        }

        final distance = _mapService.calculateDistance(
          center,
          location.position,
        );

        return distance <= radiusMeters && !location.isStale;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get nearby users: $e');
    }
  }

  /// Delete user's location from Firestore (e.g., on sign out)
  Future<void> deleteUserLocation(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user location: $e');
    }
  }

  /// Update user's sharing status
  Future<void> updateSharingStatus({
    required String userId,
    required bool isSharing,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'isSharing': isSharing,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update sharing status: $e');
    }
  }

  /// Update user's status (active, moving, stationary, offline)
  Future<void> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Clean up stale locations (older than specified duration)
  Future<void> cleanupStaleLocations({
    Duration staleDuration = const Duration(hours: 1),
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(staleDuration);

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: cutoffTime)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup stale locations: $e');
    }
  }

  /// Get total number of active users
  Future<int> getActiveUsersCount() async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isGreaterThan: fiveMinutesAgo)
          .where('isSharing', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
