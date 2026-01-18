import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_service.dart';
import 'core/services/realtime_crowd_service.dart';
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

  // 🔴 START AUTOMATIC REALTIME CROWD MONITORING FOR KUMBH MELA
  // Updates crowd levels every 5 minutes based on nearby users
  Timer.periodic(const Duration(minutes: 5), (timer) {
    RealtimeCrowdService().autoUpdateCrowdLevels();
  });

  // Initialize notification service with navigator key for deep linking
  final notificationService = NotificationService();
  await notificationService.initialize();
  notificationService.setNavigatorKey(KumbhSaathiApp.navigatorKey);

  // Initialize offline map service
  await OfflineMapService().initialize();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const KumbhSaathiApp(),
    ),
  );
}
