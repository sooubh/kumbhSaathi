// This file is DEPRECATED.
// Logic has been moved to lib/screens/auth/onboarding_screen.dart
// Retaining file temporarily to prevent breaking old imports if any exist.
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

@Deprecated('Use OnboardingScreen instead')
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingScreen();
  }
}
