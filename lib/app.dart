import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/lost/report_lost_screen.dart';
import 'screens/navigation/ghat_navigation_screen.dart';
import 'screens/emergency/sos_screen.dart';
import 'screens/voice/voice_assistant_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';

/// Main App Widget
class KumbhSaathiApp extends ConsumerWidget {
  const KumbhSaathiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Set system UI overlay style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      themeMode == ThemeMode.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.black,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.white,
            ),
    );

    return MaterialApp(
      title: 'KumbhSaathi',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/report-lost': (context) => const ReportLostScreen(),
        '/ghat-navigation': (context) => const GhatNavigationScreen(),
        '/sos': (context) => const SOSScreen(),
        '/voice-assistant': (context) => const VoiceAssistantScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
