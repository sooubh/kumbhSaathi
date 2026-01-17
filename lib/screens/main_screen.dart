import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'navigation/ghat_navigation_screen.dart';

import 'lost/lost_persons_public_screen.dart';
import 'emergency/sos_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GhatNavigationScreen(showBackButton: false),
    const LostPersonsPublicScreen(), // Public feed of lost reports
    const SOSScreen(showBackButton: false), // Need to update SOSScreen
    const ProfileScreen(showBackButton: false), // Need to update ProfileScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          indicatorColor: AppColors.primaryOrange.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primaryOrange),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppColors.primaryOrange),
              label: 'Ghats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_search_outlined),
              selectedIcon: Icon(
                Icons.person_search,
                color: AppColors.primaryOrange,
              ),
              label: 'Lost',
            ),
            NavigationDestination(
              icon: Icon(Icons.emergency_outlined),
              selectedIcon: Icon(Icons.emergency, color: AppColors.emergency),
              label: 'SOS',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primaryOrange),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
