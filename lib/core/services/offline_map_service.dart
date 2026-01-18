import 'dart:async';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

/// Service for managing offline map tile caching
/// Simplified version for flutter_map_tile_caching v10
class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  final Logger _logger = Logger();
  static const String _storeName = 'panchavati_cache';

  /// Initialize the tile caching system
  Future<void> initialize() async {
    try {
      // Create store if it doesn't exist
      final store = FMTCStore(_storeName);

      if (!(await store.manage.ready)) {
        await store.manage.create();
        _logger.i('✅ Offline map store created');
      } else {
        _logger.i('✅ Offline map store already exists');
      }
    } catch (e) {
      _logger.e('Error initializing offline map store: $e');
    }
  }

  /// Get cache information
  Future<OfflineCacheInfo> getCacheInfo() async {
    try {
      final store = FMTCStore(_storeName);

      if (!(await store.manage.ready)) {
        return OfflineCacheInfo(
          tileCount: 0,
          sizeBytes: 0,
          lastUpdated: null,
          isAvailable: false,
        );
      }

      final stats = await store.stats.all;
      final tileCount = stats.length;
      final sizeBytes = stats.size;

      return OfflineCacheInfo(
        tileCount: tileCount,
        sizeBytes: sizeBytes,
        lastUpdated: null, // Simplified - no metadata tracking for now
        isAvailable: tileCount > 0,
      );
    } catch (e) {
      _logger.e('Error getting cache info: $e');
      return OfflineCacheInfo(
        tileCount: 0,
        sizeBytes: 0,
        lastUpdated: null,
        isAvailable: false,
      );
    }
  }

  /// Clear all cached tiles
  Future<void> clearCache() async {
    try {
      final store = FMTCStore(_storeName);
      if (await store.manage.ready) {
        await store.manage.delete();
        await store.manage.create();
        _logger.i('✅ Cache cleared');
      }
    } catch (e) {
      _logger.e('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Check if offline mode is available
  Future<bool> isOfflineAvailable() async {
    final info = await getCacheInfo();
    return info.isAvailable;
  }

  /// Get the tile provider for use in FlutterMap
  /// This enables automatic caching of tiles as they are viewed
  FMTCTileProvider getTileProvider() {
    return FMTCStore(_storeName).getTileProvider();
  }
}

/// Cache information model
class OfflineCacheInfo {
  final int tileCount;
  final double sizeBytes;
  final DateTime? lastUpdated;
  final bool isAvailable;

  OfflineCacheInfo({
    required this.tileCount,
    required this.sizeBytes,
    required this.lastUpdated,
    required this.isAvailable,
  });

  String get sizeMB => (sizeBytes / 1024 / 1024).toStringAsFixed(1);

  String get formattedLastUpdate {
    if (lastUpdated == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
