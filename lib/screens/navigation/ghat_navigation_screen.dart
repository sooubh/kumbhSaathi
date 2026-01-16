import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/panchavati_config.dart';
import '../../data/models/ghat.dart';
import '../../data/models/map_marker_model.dart';
import '../../data/providers/data_providers.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/routing_provider.dart';
import '../../widgets/cards/ghat_card.dart';
import '../../widgets/map/map_widget.dart';
import '../../widgets/kumbh/panchavati_legend.dart';

/// Ghat navigation screen with map and nearby ghats
class GhatNavigationScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const GhatNavigationScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<GhatNavigationScreen> createState() =>
      _GhatNavigationScreenState();
}

class _GhatNavigationScreenState extends ConsumerState<GhatNavigationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Ghats';
  final List<String> _filters = [
    'All Ghats',
    'Low Crowd',
    'Medium Crowd',
    'High Crowd',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Ghat> _filterGhats(List<Ghat> ghats) {
    List<Ghat> filtered = ghats;

    // Filter by crowd level
    if (_selectedFilter == 'Low Crowd') {
      filtered = ghats.where((g) => g.crowdLevel == CrowdLevel.low).toList();
    } else if (_selectedFilter == 'Medium Crowd') {
      filtered = ghats.where((g) => g.crowdLevel == CrowdLevel.medium).toList();
    } else if (_selectedFilter == 'High Crowd') {
      filtered = ghats.where((g) => g.crowdLevel == CrowdLevel.high).toList();
    }

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (g) =>
                g.name.toLowerCase().contains(query) ||
                (g.nameHindi?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ghatsAsync = ref.watch(ghatsStreamProvider);

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
                // OpenStreetMap
                _buildMap(context, isDark),
                // Crowd labels from Firestore data
                ghatsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (ghats) {
                    final highCrowd = ghats
                        .where((g) => g.crowdLevel == CrowdLevel.high)
                        .length;
                    final lowCrowd = ghats
                        .where((g) => g.crowdLevel == CrowdLevel.low)
                        .length;
                    return Stack(
                      children: [
                        if (highCrowd > 0)
                          Positioned(
                            top: 40,
                            left: 20,
                            child: _buildCrowdLabel(
                              '$highCrowd HIGH CROWD',
                              AppColors.emergency,
                            ),
                          ),
                        if (lowCrowd > 0)
                          Positioned(
                            top: 100,
                            right: 40,
                            child: _buildCrowdLabel(
                              '$lowCrowd LOW CROWD',
                              AppColors.success,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                // Panchavati Legend
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: PanchavatiGhatLegend(isDark: isDark),
                ),
                // Focus Panchavati button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FocusPanchavatiButton(
                    isDark: isDark,
                    onTap: () {
                      ref.read(mapProvider.notifier).setCenter(
                            PanchavatiConfig.panchavatiCenter,
                          );
                      ref.read(mapProvider.notifier).setZoom(
                            PanchavatiConfig.optimalZoom,
                          );
                    },
                  ),
                ),
                // Map controls
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildMapControls(context, isDark, ref),
                ),
              ],
            ),
          ),
          // Bottom Sheet with Firestore data
          ghatsAsync.when(
            loading: () => _buildLoadingBottomSheet(isDark),
            error: (e, _) => _buildErrorBottomSheet(isDark, e.toString()),
            data: (ghats) =>
                _buildBottomSheet(context, isDark, _filterGhats(ghats)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBottomSheet(bool isDark) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorBottomSheet(bool isDark, String error) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.emergency),
            const SizedBox(height: 16),
            Text(
              'Failed to load ghats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkDark
                    : AppColors.textDarkLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refresh(ghatsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
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
                  if (widget.showBackButton)
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
                  if (widget.showBackButton) const SizedBox(width: 12),
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
                          'SYNCED',
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
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/sos'),
                    child: Container(
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.emergency_share,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
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
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search Ghats...',
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

  Widget _buildMap(BuildContext context, bool isDark) {
    final locationState = ref.watch(locationProvider);
    final mapState = ref.watch(mapProvider);
    final routingState = ref.watch(routingProvider);
    final ghatsAsync = ref.watch(ghatsStreamProvider);

    // Get user location
    final userLocation = locationState.currentPosition != null
        ? LatLng(
            locationState.currentPosition!.latitude,
            locationState.currentPosition!.longitude,
          )
        : null;

    // Build markers from ghats
    final markers = ghatsAsync.when(
      loading: () => <CustomMapMarker>[],
      error: (_, __) => <CustomMapMarker>[],
      data: (ghats) {
        return ghats.map((ghat) {
          Color crowdColor;
          switch (ghat.crowdLevel) {
            case CrowdLevel.low:
              crowdColor = AppColors.success;
              break;
            case CrowdLevel.medium:
              crowdColor = Colors.orange;
              break;
            case CrowdLevel.high:
              crowdColor = AppColors.emergency;
              break;
          }

          return CustomMapMarker.ghat(
            id: ghat.id,
            position: LatLng(ghat.latitude, ghat.longitude),
            name: ghat.name,
            crowdColor: crowdColor,
            metadata: {'ghat': ghat},
          );
        }).toList();
      },
    );

    return MapWidget(
      center: userLocation ?? mapState.center,
      zoom: mapState.zoom,
      markers: markers,
      route: routingState.calculatedRoute,
      userLocation: userLocation,
      showUserLocation: true,
      onMarkerTap: (marker) {
        ref.read(mapProvider.notifier).selectMarker(marker);
        // Show ghat details
        if (marker.metadata != null && marker.metadata!['ghat'] != null) {
          _showGhatDetails(context, marker.metadata!['ghat'] as Ghat);
        }
      },
      onLongPress: (position) {
        // Start navigation to this point
        _startNavigation(context, ref, position);
      },
    );
  }

  void _showGhatDetails(BuildContext context, Ghat ghat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ghat.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ghat.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _startNavigation(
                  context,
                  ref,
                  LatLng(ghat.latitude, ghat.longitude),
                  name: ghat.name,
                );
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Navigate Here'),
            ),
          ],
        ),
      ),
    );
  }

  void _startNavigation(
    BuildContext context,
    WidgetRef ref,
    LatLng destination, {
    String? name,
  }) {
    final locationState = ref.read(locationProvider);
    if (locationState.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your location')),
      );
      return;
    }

    final start = LatLng(
      locationState.currentPosition!.latitude,
      locationState.currentPosition!.longitude,
    );

    ref.read(routingProvider.notifier).setStartPoint(start, name: 'Your Location');
    ref.read(routingProvider.notifier).setEndPoint(destination, name: name);
    ref.read(routingProvider.notifier).calculateRoute();
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

  Widget _buildMapControls(BuildContext context, bool isDark, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);

    return Column(
      children: [
        // Location tracking button
        GestureDetector(
          onTap: () {
            ref.read(mapProvider.notifier).toggleTracking();
            ref.read(locationProvider.notifier).getCurrentLocation();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mapState.isTracking
                  ? AppColors.primaryBlue
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: mapState.isTracking
                    ? AppColors.primaryBlue
                    : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
              ),
              boxShadow: [
                BoxShadow(
                  color: mapState.isTracking
                      ? AppColors.primaryBlue.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              Icons.my_location,
              color: mapState.isTracking
                  ? Colors.white
                  : (isDark ? AppColors.textDarkDark : AppColors.textDarkLight),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Zoom controls
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
                onPressed: () => ref.read(mapProvider.notifier).zoomIn(),
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
                onPressed: () => ref.read(mapProvider.notifier).zoomOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    bool isDark,
    List<Ghat> ghats,
  ) {
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
                'Nearby Ghats (${ghats.length})',
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
            child: ghats.isEmpty
                ? Center(
                    child: Text(
                      'No ghats found',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ghats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return GhatCard(
                        ghat: ghats[index],
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
