import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'navigation/ghat_navigation_screen.dart';
import 'family/family_group_screen.dart';
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
    const FamilyGroupScreen(), // Family tracking groups
    const SOSScreen(showBackButton: false),
    const ProfileScreen(showBackButton: false), // Includes Lost Persons access
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
          height: 70,
          destinations: [
            _buildNavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              index: 0,
              isSelected: _selectedIndex == 0,
            ),
            _buildNavDestination(
              icon: Icons.map_outlined,
              selectedIcon: Icons.map,
              label: 'Ghats',
              index: 1,
              isSelected: _selectedIndex == 1,
            ),
            _buildNavDestination(
              icon: Icons.group_outlined,
              selectedIcon: Icons.group,
              label: 'Family',
              index: 2,
              isSelected: _selectedIndex == 2,
            ),
            _buildNavDestination(
              icon: Icons.emergency_outlined,
              selectedIcon: Icons.emergency,
              label: 'SOS',
              index: 3,
              isSelected: _selectedIndex == 3,
              selectedColor: AppColors.emergency,
            ),
            _buildNavDestination(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              index: 4,
              isSelected: _selectedIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
    Color selectedColor = AppColors.primaryOrange,
  }) {
    return NavigationDestination(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isSelected ? -8 : 0, 0),
        child: Icon(icon),
      ),
      selectedIcon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, isSelected ? -8 : 0, 0),
        child: Icon(selectedIcon, color: selectedColor),
      ),
      label: label,
    );
  }
}
