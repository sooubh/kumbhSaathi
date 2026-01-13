import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ghat.dart';
import '../../widgets/common/action_card.dart';
import '../../widgets/cards/live_status_card.dart';
import '../lost/report_lost_screen.dart';
import '../navigation/ghat_navigation_screen.dart';
import '../emergency/sos_screen.dart';
import '../voice/voice_assistant_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

/// Home screen / Dashboard
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(context, isDark),
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Live Status Card
                    LiveStatusCard(
                      locationName: 'Sangam Ghat Live',
                      crowdLevel: CrowdLevel.high,
                      percentage: 85,
                      suggestion: 'Avoid main entry point',
                      onTap: () =>
                          _navigateTo(context, const GhatNavigationScreen()),
                    ),
                    const SizedBox(height: 24),
                    // Action Grid
                    _buildActionGrid(context),
                    const SizedBox(height: 24),
                    // Ask AI Button
                    _buildAskAIButton(context, isDark),
                    const SizedBox(height: 16),
                    // Language Indicator
                    _buildLanguageIndicator(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
            .withValues(alpha: 0.9),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.temple_hindu,
                  color: AppColors.primaryOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KumbhSaathi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                  Text(
                    'NASHIK KUMBH 2025',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Action Buttons
          Row(
            children: [
              _AppBarButton(
                icon: Icons.account_circle,
                onTap: () => _navigateTo(context, const ProfileScreen()),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _AppBarButton(
                icon: Icons.settings,
                onTap: () => _navigateTo(context, const SettingsScreen()),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: [
        ActionCard(
          title: 'Voice Help',
          icon: Icons.mic,
          isPrimary: true,
          onTap: () => _navigateTo(context, const VoiceAssistantScreen()),
        ),
        ActionCard(
          title: 'Emergency',
          icon: Icons.emergency_share,
          isEmergency: true,
          onTap: () => _navigateTo(context, const SOSScreen()),
        ),
        ActionCard(
          title: 'I Am Lost',
          icon: Icons.person_search,
          iconColor: Colors.grey[600],
          onTap: () => _navigateTo(context, const ReportLostScreen()),
        ),
        ActionCard(
          title: 'Find Ghat',
          icon: Icons.water_drop,
          iconColor: AppColors.primaryBlue,
          onTap: () => _navigateTo(context, const GhatNavigationScreen()),
        ),
      ],
    );
  }

  Widget _buildAskAIButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateTo(context, const VoiceAssistantScreen()),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves, size: 30, color: AppColors.primaryOrange),
            const SizedBox(width: 16),
            Text(
              'Ask Seva AI',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.textDarkDark
                    : AppColors.textDarkLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'ENGLISH SUPPORT ACTIVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _AppBarButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
          size: 24,
        ),
      ),
    );
  }
}
