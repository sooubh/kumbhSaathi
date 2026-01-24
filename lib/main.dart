
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'core/services/firebase_service.dart';

import 'core/services/notification_service.dart';
import 'core/services/offline_map_service.dart';
import 'app.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize mobile-only services
  if (!kIsWeb) {
    // 🔴 FMTC Init handled by OfflineMapService
    // try {
    //   await FlutterMapTileCaching.initialise();
    //   await FMTC.instance('root').manage.createAsync();
    // } catch (e) {
    //   Logger().e('FMTC Init Failed: $e');
    // }



    // Initialize notification service with navigator key for deep linking
    final notificationService = NotificationService();
    await notificationService.initialize();
    notificationService.setNavigatorKey(KumbhSaathiApp.navigatorKey);

    // Initialize offline map service
    await OfflineMapService().initialize();
  } else {
    Logger().i(
      '🌐 [WEB] Skipping mobile-only services (notifications, offline maps, crowd monitoring)',
    );
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const KumbhSaathiApp(),
    ),
  );
}
