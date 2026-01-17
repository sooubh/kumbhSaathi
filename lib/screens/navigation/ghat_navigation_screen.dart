import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  final String? initialSearchQuery;
  final LatLng? targetLocation;

  const GhatNavigationScreen({
    super.key,
    this.showBackButton = true,
    this.initialSearchQuery,
    this.targetLocation,
  });

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
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }

    // If target location is provided, set map center
    if (widget.targetLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapProvider.notifier).setCenter(widget.targetLocation!);
        ref
            .read(mapProvider.notifier)
            .setZoom(PanchavatiConfig.maxZoom); // Zoom in on target
      });
    }
  }

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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 1: Full Screen Map
          Positioned.fill(child: _buildMapLayer(context, isDark, ghatsAsync)),

          // Layer 2: Floating Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildFloatingHeader(context, isDark)),
          ),

          // Layer 3: Draggable Bottom Sheet
          Positioned.fill(
            child: ghatsAsync.when(
              loading: () => const SizedBox(),
              error: (error, stackTrace) => const SizedBox(),
              data: (ghats) => _buildDraggableBottomSheet(
                context,
                isDark,
                _filterGhats(ghats),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayer(
    BuildContext context,
    bool isDark,
    AsyncValue<List<Ghat>> ghatsAsync,
  ) {
    return Stack(
      children: [
        // The Map
        _buildMapBase(context, isDark),

        // Crowd Labels
        ghatsAsync.when(
          loading: () => const SizedBox(),
          error: (error, stackTrace) => const SizedBox(),
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
                    top: 140, // Below header
                    left: 16,
                    child: _buildCrowdLabel(
                      '$highCrowd HIGH CROWD',
                      AppColors.emergency,
                    ),
                  ),
                if (lowCrowd > 0)
                  Positioned(
                    top: 140,
                    right: 16,
                    child: _buildCrowdLabel(
                      '$lowCrowd LOW CROWD',
                      AppColors.success,
                    ),
                  ),
              ],
            );
          },
        ),

        // Map Controls (Moved up)
        Positioned(
          right: 16,
          bottom: 240,
          child: _buildMapControls(context, isDark, ref),
        ),

        // Focus Button (Moved lower to avoid overlap with crowd labels)
        Positioned(
          top: 200,
          right: 16,
          child: FocusPanchavatiButton(
            isDark: isDark,
            onTap: () {
              ref
                  .read(mapProvider.notifier)
                  .setCenter(PanchavatiConfig.panchavatiCenter);
              ref
                  .read(mapProvider.notifier)
                  .setZoom(PanchavatiConfig.optimalZoom);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableBottomSheet(
    BuildContext context,
    bool isDark,
    List<Ghat> ghats,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header of Sheet
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Ghats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${ghats.length} found',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: ghats.isEmpty
                    ? Center(
                        child: Text(
                          'No ghats match your filter',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ghats.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GhatCard(
                              ghat: ghats[index],
                              onNavigate: () {
                                _startNavigation(
                                  context,
                                  ref,
                                  LatLng(
                                    ghats[index].latitude,
                                    ghats[index].longitude,
                                  ),
                                  name: ghats[index].name,
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingHeader(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.showBackButton)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                ),
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
                      fontSize: 14,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      size: 22,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clear button
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          ),
                        // Voice search button
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? AppColors.primaryBlue
                                : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                          ),
                          onPressed: _listen,
                        ),
                      ],
                    ),
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                ),
              ),
              // Panchavati Ghats Dropdown Menu
              PopupMenuButton<String>(
                tooltip: 'Panchavati Ghats',
                icon: Icon(
                  Icons.location_city,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                itemBuilder: (context) => _buildPanchavatiGhatsMenu(),
              ),
              // Filter Menu
              PopupMenuButton<String>(
                initialValue: _selectedFilter,
                onSelected: (value) => setState(() => _selectedFilter = value),
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedFilter == 'All Ghats'
                      ? (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight)
                      : AppColors.primaryBlue,
                ),
                itemBuilder: (context) => _filters.map((filter) {
                  return PopupMenuItem(value: filter, child: Text(filter));
                }).toList(),
              ),
            ],
          ),
          // Active Filter Chips (Horizontal)
          if (_selectedFilter != 'All Ghats') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedFilter,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilter = 'All Ghats'),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapBase(BuildContext context, bool isDark) {
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
      error: (error, stackTrace) => <CustomMapMarker>[],
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
      showSatellite: mapState.showSatellite,
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(ghat.description, style: const TextStyle(fontSize: 14)),
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

    ref
        .read(routingProvider.notifier)
        .setStartPoint(start, name: 'Your Location');
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

  List<PopupMenuEntry<String>> _buildPanchavatiGhatsMenu() {
    final ghatNames = {
      'someshwar_ghat': '1. Someshwar Ghat',
      'ahilya_ghat': '2. Ahilya Ghat',
      'naroshankar_ghat': '3. Naroshankar Ghat',
      'ram_ghat': '4. Ram Ghat ⭐',
      'kala_ram_ghat': '5. Kala Ram Ghat',
      'ganga_ghat': '6. Ganga Ghat',
      'tapovan_ghat': '7. Tapovan Ghat',
    };

    return [
      PopupMenuItem<String>(
        enabled: false,
        child: Text(
          'Panchavati Ghats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      const PopupMenuDivider(),
      ...PanchavatiConfig.ghatPilgrimageOrder.map((ghatId) {
        final isMain = ghatId == 'ram_ghat';
        return PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isMain ? AppColors.primaryBlue : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ghatNames[ghatId] ?? ghatId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isMain ? FontWeight.w700 : FontWeight.w500,
                  color: isMain ? AppColors.primaryBlue : null,
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (!mounted) return;
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (!mounted) return;
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Voice error: ${val.errorMsg}')),
          );
        },
      );

      if (!mounted) return;

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
              // Trigger filter update
            });
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice recognition not available')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Widget _buildMapControls(BuildContext context, bool isDark, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);

    return Column(
      children: [
        // Satellite Toggle
        GestureDetector(
          onTap: () {
            ref.read(mapProvider.notifier).toggleSatellite();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: mapState.showSatellite
                  ? AppColors.primaryBlue
                  : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: mapState.showSatellite
                    ? AppColors.primaryBlue
                    : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
              ),
              boxShadow: [
                BoxShadow(
                  color: mapState.showSatellite
                      ? AppColors.primaryBlue.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              Icons.satellite_alt,
              color: mapState.showSatellite
                  ? Colors.white
                  : (isDark ? AppColors.textDarkDark : AppColors.textDarkLight),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
}
