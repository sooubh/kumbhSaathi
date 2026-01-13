import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ghat.dart';
import '../../widgets/cards/ghat_card.dart';

/// Ghat navigation screen with map and nearby ghats
class GhatNavigationScreen extends StatefulWidget {
  const GhatNavigationScreen({super.key});

  @override
  State<GhatNavigationScreen> createState() => _GhatNavigationScreenState();
}

class _GhatNavigationScreenState extends State<GhatNavigationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Ghats';
  final List<String> _filters = [
    'All Ghats',
    'Emergency',
    'Medical',
    'Parking',
  ];

  // Sample data
  final List<Ghat> _nearbyGhats = [
    Ghat(
      id: '1',
      name: 'Triveni Sangam',
      nameHindi: 'त्रिवेणी संगम',
      description: 'Main confluence point',
      latitude: 20.0063,
      longitude: 73.7897,
      distanceKm: 1.2,
      walkTimeMinutes: 15,
      crowdLevel: CrowdLevel.high,
      bestTimeStart: '4:00 AM',
      bestTimeEnd: '6:00 AM',
    ),
    Ghat(
      id: '2',
      name: 'Dashashwamedh',
      nameHindi: 'दशाश्वमेध',
      description: 'Popular ghat',
      latitude: 20.0100,
      longitude: 73.7900,
      distanceKm: 0.6,
      walkTimeMinutes: 8,
      crowdLevel: CrowdLevel.low,
      isGoodForBathing: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          _buildHeader(context, isDark),
          // Map Area
          Expanded(
            child: Stack(
              children: [
                // Map placeholder
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : const Color(0xFFF1F5F9),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://maps.googleapis.com/maps/api/staticmap?center=20.0063,73.7897&zoom=14&size=600x400&maptype=roadmap',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.6,
                    ),
                  ),
                  child: _buildMapPlaceholder(isDark),
                ),
                // Crowd labels
                Positioned(
                  top: 40,
                  left: 20,
                  child: _buildCrowdLabel('HIGH CROWD', AppColors.emergency),
                ),
                Positioned(
                  top: 100,
                  right: 40,
                  child: _buildCrowdLabel('LOW CROWD', AppColors.success),
                ),
                // Map controls
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildMapControls(isDark),
                ),
              ],
            ),
          ),
          // Bottom Sheet
          _buildBottomSheet(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : const Color(0xFFF9FAFB),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ghat Navigation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Offline badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_done,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // SOS button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emergency,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergency.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emergency_share,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Ghats, Parking, Toilets...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : (isDark ? AppColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(100),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE5E7EB),
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? AppColors.textDarkDark
                                      : AppColors.textDarkLight),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.expand_more,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 8),
          Text(
            'Map View',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          Text(
            'Google Maps API key required',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls(bool isDark) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.near_me, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
                onPressed: () {},
              ),
              Container(
                height: 1,
                width: 24,
                color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
              ),
              IconButton(
                icon: Icon(
                  Icons.remove,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Ghats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ghat cards horizontal list
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyGhats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return GhatCard(
                  ghat: _nearbyGhats[index],
                  onNavigate: () {
                    // TODO: Start navigation
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Home indicator
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
