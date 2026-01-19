import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ghat.dart';
import '../../data/models/facility.dart';
import '../../data/providers/data_providers.dart';
import '../../widgets/common/action_card.dart';
import '../../widgets/common/chatbot_button.dart';
import '../../widgets/cards/live_status_card.dart';
import '../../widgets/cards/facility_card.dart';
import '../lost/report_lost_screen.dart';
import '../navigation/ghat_navigation_screen.dart';
import '../lost/lost_persons_public_screen.dart';
import '../emergency/sos_screen.dart';
import '../voice/voice_assistant_sheet.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../facilities/add_facility_screen.dart';
import '../facilities/facility_detail_sheet.dart';
import '../../core/services/firebase_service.dart';

/// Home screen / Dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  FacilityType? _selectedFacilityType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ghatsAsync = ref.watch(ghatsStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
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
                        // Live Status Card - now with Firestore data
                        ghatsAsync.when(
                          loading: () => _buildLoadingCard(isDark),
                          error: (e, _) => _buildDefaultStatusCard(context),
                          data: (ghats) {
                            if (ghats.isEmpty) {
                              return _buildDefaultStatusCard(context);
                            }
                            // Find the most crowded ghat
                            final mostCrowdedGhat = ghats.reduce(
                              (a, b) => a.crowdLevel.index > b.crowdLevel.index
                                  ? a
                                  : b,
                            );
                            return LiveStatusCard(
                              locationName: '${mostCrowdedGhat.name} Live',
                              crowdLevel: mostCrowdedGhat.crowdLevel,
                              percentage: _getCrowdPercentage(
                                mostCrowdedGhat.crowdLevel,
                              ),
                              suggestion: _getSuggestion(
                                mostCrowdedGhat.crowdLevel,
                              ),
                              onTap: () => _navigateTo(
                                context,
                                const GhatNavigationScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Action Grid
                        _buildActionGrid(context),
                        const SizedBox(height: 32),
                        // Facilities Section
                        _buildFacilitiesSection(context, isDark),
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
          // Chatbot Button
          const Positioned(right: 16, bottom: 16, child: ChatbotButton()),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDefaultStatusCard(BuildContext context) {
    return LiveStatusCard(
      locationName: 'Sangam Ghat Live',
      crowdLevel: CrowdLevel.medium,
      percentage: 50,
      suggestion: 'Loading live data...',
      onTap: () => _navigateTo(context, const GhatNavigationScreen()),
    );
  }

  int _getCrowdPercentage(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 30;
      case CrowdLevel.medium:
        return 55;
      case CrowdLevel.high:
        return 85;
    }
  }

  String _getSuggestion(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 'Good time for darshan';
      case CrowdLevel.medium:
        return 'Moderate crowd expected';
      case CrowdLevel.high:
        return 'Avoid main entry point';
    }
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
              // App Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
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
          onTap: () => _showVoiceAssistant(context),
        ),
        ActionCard(
          title: 'Emergency',
          icon: Icons.emergency_share,
          isEmergency: true,
          onTap: () => _navigateTo(context, const SOSScreen()),
        ),
        ActionCard(
          title: 'Lost Persons',
          icon: Icons.person_search,
          onTap: () => _navigateTo(context, const LostPersonsPublicScreen()),
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
        if (FirebaseService.isLoggedIn)
          ActionCard(
            title: 'Add Place',
            icon: Icons.add_location_alt,
            iconColor: Colors.orange,
            onTap: () => _navigateTo(context, const AddFacilityScreen()),
          ),
      ],
    );
  }

  Widget _buildAskAIButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showVoiceAssistant(context),
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

  Widget _buildFacilitiesSection(BuildContext context, bool isDark) {
    final facilitiesAsync = ref.watch(facilitiesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby Facilities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find washrooms, medical help, food & more',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category Filter Pills
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryPill('All', null, isDark),
              _buildCategoryPill('Washroom', FacilityType.washroom, isDark),
              _buildCategoryPill('Medical', FacilityType.medical, isDark),
              _buildCategoryPill('Food', FacilityType.food, isDark),
              _buildCategoryPill('Police', FacilityType.police, isDark),
              _buildCategoryPill(
                'Charging',
                FacilityType.chargingPoint,
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Facility Cards
        facilitiesAsync.when(
          loading: () => const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 110,
            child: Center(
              child: Text(
                'Failed to load facilities',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
            ),
          ),
          data: (allFacilities) {
            // Filter by selected type
            final facilities = _selectedFacilityType == null
                ? allFacilities
                : allFacilities
                      .where((f) => f.type == _selectedFacilityType)
                      .toList();

            if (facilities.isEmpty) {
              return SizedBox(
                height: 110,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 40,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFacilityType == null
                            ? 'No facilities found nearby'
                            : 'No ${_selectedFacilityType!.displayName} facilities found',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: facilities.length,
                itemBuilder: (context, index) {
                  return FacilityCard(
                    facility: facilities[index],
                    onTap: () {
                      // Show facility detail sheet with navigation options
                      FacilityDetailSheet.show(context, facilities[index]);
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryPill(String label, FacilityType? type, bool isDark) {
    final isSelected = _selectedFacilityType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFacilityType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange
              : (isDark ? AppColors.cardDark : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textDarkDark : AppColors.textDarkLight),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showVoiceAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceAssistantSheet(),
    );
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
