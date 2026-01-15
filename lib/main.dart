import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_service.dart';
import 'core/services/realtime_crowd_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initialize();

  // 🔴 START AUTOMATIC REALTIME CROWD MONITORING FOR KUMBH MELA
  // Updates crowd levels every 5 minutes based on nearby users
  Timer.periodic(const Duration(minutes: 5), (timer) {
    RealtimeCrowdService().autoUpdateCrowdLevels();
  });

  runApp(const ProviderScope(child: KumbhSaathiApp()));
}
