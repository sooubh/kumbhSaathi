import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:logger/logger.dart';

/// Service for managing offline map tile caching
/// Simplified version for flutter_map_tile_caching v10
class OfflineMapService {
  static final OfflineMapService _instance = OfflineMapService._internal();
  factory OfflineMapService() => _instance;
  OfflineMapService._internal();

  final Logger _logger = Logger();
  static const String _storeName = 'panchavati_cache';

  bool _isReady = false;

  /// Initialize the tile caching system
  Future<void> initialize() async {
    try {
      _logger.i('🗺️ Initializing OfflineMapService...');

      // Create store if it doesn't exist
      final store = FMTCStore(_storeName);

      // Note: FMTC v10 handles caching differently.
      // We will rely on manual cleaning for now or correct API later.
      await store.manage.create();

      // Simple readiness check
      try {
        await store.manage.create();

        // --- OPTIMIZATION: Check Size and Prune if needed ---
        try {
          // If stats calculation fails, we ignore optimization to avoid breaking init
          final size = (await store.stats.all).size;
          final maxBytes = 500 * 1024 * 1024; // 500MB

          if (size > maxBytes) {
            _logger.w(
              '⚠️ Cache exceeded 500MB ($size bytes). Clearing to prevent crashes.',
            );
            await store.manage.delete();
            await store.manage.create();
            _logger.i('✅ Cache reset successfully.');
          }
        } catch (e) {
          _logger.w('Could not check cache stats: $e');
        }
        // ----------------------------------------------------

        _isReady = true;
        _logger.i('✅ Offline map store initialized');
      } catch (e) {
        _logger.w('⚠️ Map store might already exist or error: $e');
        // Verify if it's actually usable
        if (await store.manage.ready) {
          _isReady = true;
          _logger.i('✅ Offline map store confirmed ready');
        } else {
          _logger.e('❌ Offline map store failed to initialize');
          // Attempt recovery by deleting and recreating
          try {
            _logger.i('🔄 Attempting store recovery...');
            await store.manage.delete();
            await store.manage.create();
            _isReady = true;
            _logger.i('✅ Offline map store recovered');
          } catch (recoveryError) {
            _logger.e('❌ Store recovery failed: $recoveryError');
          }
        }
      }
    } catch (e) {
      _logger.e('Error initializing offline map store: $e');
    }
  }

  /// Verify store integrity
  Future<bool> verifyStore() async {
    if (!_isReady) return false;
    try {
      final store = FMTCStore(_storeName);
      return await store.manage.ready;
    } catch (e) {
      _logger.e('Store verification failed: $e');
      return false;
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
          isError: false,
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
        isError: false,
      );
    } catch (e) {
      _logger.e('Error getting cache info: $e');
      return OfflineCacheInfo(
        tileCount: 0,
        sizeBytes: 0,
        lastUpdated: null,
        isAvailable: false,
        isError: true,
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
  TileProvider getTileProvider() {
    if (!_isReady) {
      _logger.w(
        '⚠️ Map Store not ready, returning default NetworkTileProvider',
      );
      return NetworkTileProvider();
    }
    return FMTCTileProvider(stores: {_storeName: null});
  }
}

/// Cache information model
class OfflineCacheInfo {
  final int tileCount;
  final double sizeBytes;
  final DateTime? lastUpdated;
  final bool isAvailable;
  final bool isError;

  OfflineCacheInfo({
    required this.tileCount,
    required this.sizeBytes,
    required this.lastUpdated,
    required this.isAvailable,
    this.isError = false,
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
