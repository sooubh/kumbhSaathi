import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/custom_walking_path.dart';
import 'map_service.dart';

/// Service for managing custom walking paths
class CustomPathService {
  static final CustomPathService _instance = CustomPathService._internal();
  factory CustomPathService() => _instance;
  CustomPathService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapService _mapService = MapService();

  static const String _collectionName = 'custom_walking_paths';

  /// Save a new custom path
  Future<String> savePath(CustomWalkingPath path) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(path.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save path: $e');
    }
  }

  /// Get all paths between two locations
  Future<List<CustomWalkingPath>> getPathsBetween({
    required String startLocationId,
    required String endLocationId,
  }) async {
    try {
      // Try both directions
      final query1 = await _firestore
          .collection(_collectionName)
          .where('startLocationId', isEqualTo: startLocationId)
          .where('endLocationId', isEqualTo: endLocationId)
          .get();

      final query2 = await _firestore
          .collection(_collectionName)
          .where('startLocationId', isEqualTo: endLocationId)
          .where('endLocationId', isEqualTo: startLocationId)
          .get();

      final paths = <CustomWalkingPath>[];

      for (final doc in query1.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        paths.add(CustomWalkingPath.fromJson(data));
      }

      for (final doc in query2.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        // Reverse waypoints for opposite direction
        final path = CustomWalkingPath.fromJson(data);
        final reversedPath = CustomWalkingPath(
          id: path.id,
          name: '${path.name} (Reverse)',
          description: path.description,
          startLocationId: path.endLocationId,
          endLocationId: path.startLocationId,
          startLocationName: path.endLocationName,
          endLocationName: path.startLocationName,
          waypoints: path.waypoints.reversed.toList(),
          distanceMeters: path.distanceMeters,
          durationSeconds: path.durationSeconds,
          createdBy: path.createdBy,
          createdByName: path.createdByName,
          createdAt: path.createdAt,
          upvotes: path.upvotes,
          downvotes: path.downvotes,
          isWalkingOnly: path.isWalkingOnly,
          isVerified: path.isVerified,
          tags: path.tags,
          photoUrl: path.photoUrl,
        );
        paths.add(reversedPath);
      }

      // Sort by rating (highest first)
      paths.sort((a, b) => b.rating.compareTo(a.rating));

      return paths;
    } catch (e) {
      throw Exception('Failed to get paths: $e');
    }
  }

  /// Stream all custom paths (for map overlay)
  Stream<List<CustomWalkingPath>> streamAllPaths() {
    return _firestore
        .collection(_collectionName)
        .where('isVerified', isEqualTo: true) // Only verified paths
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomWalkingPath.fromJson(data);
      }).toList();
    });
  }

  /// Get path by ID
  Future<CustomWalkingPath?> getPathById(String pathId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(pathId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return CustomWalkingPath.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Upvote a path
  Future<void> upvotePath(String pathId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(pathId).update({
        'upvotes': FieldValue.increment(1),
      });

      // Record user's vote
      await _firestore
          .collection('path_votes')
          .doc('${pathId}_$userId')
          .set({
        'pathId': pathId,
        'userId': userId,
        'vote': 'up',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to upvote: $e');
    }
  }

  /// Downvote a path
  Future<void> downvotePath(String pathId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(pathId).update({
        'downvotes': FieldValue.increment(1),
      });

      // Record user's vote
      await _firestore
          .collection('path_votes')
          .doc('${pathId}_$userId')
          .set({
        'pathId': pathId,
        'userId': userId,
        'vote': 'down',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to downvote: $e');
    }
  }

  /// Check if user has voted on a path
  Future<String?> getUserVote(String pathId, String userId) async {
    try {
      final doc = await _firestore
          .collection('path_votes')
          .doc('${pathId}_$userId')
          .get();

      if (!doc.exists) return null;

      return doc.data()?['vote'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get popular paths (verified + highly rated)
  Future<List<CustomWalkingPath>> getPopularPaths() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isVerified', isEqualTo: true)
          .orderBy('upvotes', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomWalkingPath.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a path (only by creator or admin)
  Future<void> deletePath(String pathId, String userId) async {
    try {
      final path = await getPathById(pathId);
      if (path == null) return;

      // Only creator can delete
      if (path.createdBy != userId) {
        throw Exception('Not authorized to delete this path');
      }

      await _firestore.collection(_collectionName).doc(pathId).delete();
    } catch (e) {
      throw Exception('Failed to delete path: $e');
    }
  }

  /// Get user's contributed paths
  Future<List<CustomWalkingPath>> getUserPaths(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CustomWalkingPath.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
