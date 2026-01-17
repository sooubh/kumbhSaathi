import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../../data/models/ghat.dart';

/// Service for realtime crowd monitoring at ghats
class RealtimeCrowdService {
  static final RealtimeCrowdService _instance =
      RealtimeCrowdService._internal();
  factory RealtimeCrowdService() => _instance;
  RealtimeCrowdService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = Logger();

  /// Stream realtime crowd levels for all ghats
  Stream<Map<String, CrowdLevel>> streamCrowdLevels() {
    return _firestore.collection('ghats').snapshots().map((snapshot) {
      final crowdMap = <String, CrowdLevel>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final crowdLevelString = data['crowdLevel'] as String?;
        if (crowdLevelString != null) {
          crowdMap[doc.id] = CrowdLevel.values.firstWhere(
            (e) => e.name == crowdLevelString,
            orElse: () => CrowdLevel.low,
          );
        }
      }
      return crowdMap;
    });
  }

  /// Update crowd level for a specific ghat
  /// This would typically be called by admin app or automated system
  Future<void> updateCrowdLevel({
    required String ghatId,
    required CrowdLevel newLevel,
  }) async {
    try {
      await _firestore.collection('ghats').doc(ghatId).update({
        'crowdLevel': newLevel.name,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update crowd level: $e');
    }
  }

  /// Estimate crowd level based on number of users nearby
  /// Call this periodically to auto-update crowd levels
  Future<void> autoUpdateCrowdLevels() async {
    try {
      // Get all ghats
      final ghatsSnapshot = await _firestore.collection('ghats').get();

      // Get all user locations
      final locationsSnapshot = await _firestore
          .collection('user_locations')
          .get();

      for (final ghatDoc in ghatsSnapshot.docs) {
        final ghatData = ghatDoc.data();
        final ghatLat = ghatData['latitude'] as double;
        final ghatLng = ghatData['longitude'] as double;

        // Count users within 100m radius
        int nearbyUsers = 0;
        for (final locDoc in locationsSnapshot.docs) {
          final locData = locDoc.data();
          final userLat = locData['latitude'] as double;
          final userLng = locData['longitude'] as double;

          // Simple distance check (not accurate but fast)
          final distance = _calculateSimpleDistance(
            ghatLat,
            ghatLng,
            userLat,
            userLng,
          );

          if (distance < 0.001) {
            // ~100m
            nearbyUsers++;
          }
        }

        // Determine crowd level based on user count
        CrowdLevel newLevel;
        if (nearbyUsers < 10) {
          newLevel = CrowdLevel.low;
        } else if (nearbyUsers < 50) {
          newLevel = CrowdLevel.medium;
        } else {
          newLevel = CrowdLevel.high;
        }

        // Update ghat crowd level
        await _firestore.collection('ghats').doc(ghatDoc.id).update({
          'crowdLevel': newLevel.name,
          'userCount': nearbyUsers,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.e('Auto-update crowd levels failed: $e');
    }
  }

  /// Simple distance calculation (not Haversine, just for rough estimate)
  double _calculateSimpleDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = lat1 - lat2;
    final dLng = lng1 - lng2;
    return (dLat * dLat + dLng * dLng);
  }

  /// Get crowd statistics for dashboard
  Future<Map<String, dynamic>> getCrowdStats() async {
    try {
      final ghatsSnapshot = await _firestore.collection('ghats').get();

      int totalGhats = 0;
      int lowCrowd = 0;
      int mediumCrowd = 0;
      int highCrowd = 0;

      for (final doc in ghatsSnapshot.docs) {
        totalGhats++;
        final data = doc.data();
        final crowdLevel = data['crowdLevel'] as String?;

        if (crowdLevel == 'low') {
          lowCrowd++;
        } else if (crowdLevel == 'medium') {
          mediumCrowd++;
        } else if (crowdLevel == 'high') {
          highCrowd++;
        }
      }

      return {
        'totalGhats': totalGhats,
        'lowCrowd': lowCrowd,
        'mediumCrowd': mediumCrowd,
        'highCrowd': highCrowd,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      return {'error': e.toString(), 'timestamp': DateTime.now()};
    }
  }

  /// Stream crowd stats in realtime
  Stream<Map<String, dynamic>> streamCrowdStats() {
    return _firestore.collection('ghats').snapshots().map((snapshot) {
      int totalGhats = 0;
      int lowCrowd = 0;
      int mediumCrowd = 0;
      int highCrowd = 0;

      for (final doc in snapshot.docs) {
        totalGhats++;
        final data = doc.data();
        final crowdLevel = data['crowdLevel'] as String?;

        if (crowdLevel == 'low') {
          lowCrowd++;
        } else if (crowdLevel == 'medium') {
          mediumCrowd++;
        } else if (crowdLevel == 'high') {
          highCrowd++;
        }
      }

      return {
        'totalGhats': totalGhats,
        'lowCrowd': lowCrowd,
        'mediumCrowd': mediumCrowd,
        'highCrowd': highCrowd,
        'timestamp': DateTime.now(),
      };
    });
  }
}
