import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/ghat.dart';

/// Service for realtime crowd monitoring at ghats
class RealtimeCrowdService {
  static final RealtimeCrowdService _instance =
      RealtimeCrowdService._internal();
  factory RealtimeCrowdService() => _instance;
  RealtimeCrowdService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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
