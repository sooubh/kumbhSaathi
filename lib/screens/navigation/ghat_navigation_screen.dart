import 'dart:ui';
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
import '../../widgets/cards/facility_card.dart';
import '../../screens/facilities/facility_detail_sheet.dart';
import '../../data/models/facility.dart';
import '../../widgets/map/map_widget.dart';
import '../../widgets/kumbh/panchavati_legend.dart';
import '../../data/models/lost_person.dart';

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
  
  String _mapCategory = 'All';
  final List<String> _mapCategories = ['All', 'Ghats', 'Facilities', 'Lost Persons'];
  
  String _selectedFilter = 'All Ghats';
  final List<String> _filters = [
    'All Ghats',
    'Low Crowd',
    'Medium Crowd',
    'High Crowd',
  ];
  
  FacilityType? _selectedFacilityType;
  LostPersonStatus? _selectedLostStatus;

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

  List<Facility> _filterFacilities(List<Facility> facilities) {
    List<Facility> filtered = facilities;
    
    // Filter by type
    if (_selectedFacilityType != null) {
      filtered = filtered.where((f) => f.type == _selectedFacilityType).toList();
    }
    
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (f) =>
                f.name.toLowerCase().contains(query) ||
                f.nameHindi.toLowerCase().contains(query) ||
                f.type.displayName.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  List<LostPerson> _filterLostPersons(List<LostPerson> lost) {
    List<LostPerson> filtered = lost;

    if (_selectedLostStatus != null) {
      filtered = filtered.where((p) => p.status == _selectedLostStatus).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.lastSeenLocation.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  double _getItemDistance(dynamic item) {
    if (item is Ghat) return item.distanceKm * 1000;
    if (item is Facility) return item.distanceMeters;
    if (item is LostPerson) return 0; // Show lost persons first as they are critical
    return 999999;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ghatsAsync = ref.watch(ghatsStreamProvider);
    final facilitiesAsync = ref.watch(facilitiesStreamProvider);
    final lostPersonsAsync = ref.watch(lostPersonsStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 1: Full Screen Map
          Positioned.fill(child: _buildMapLayer(context, isDark, ghatsAsync, facilitiesAsync, lostPersonsAsync)),

          // Layer 2: Draggable Bottom Sheet
          Positioned.fill(
            child: _mapCategory == 'All'
              ? _buildDraggableBottomSheetAll(
                  context,
                  isDark,
                  [
                    ...(ghatsAsync.hasValue ? _filterGhats(ghatsAsync.value!) : []),
                    ...(facilitiesAsync.hasValue ? _filterFacilities(facilitiesAsync.value!) : []),
                    ...(lostPersonsAsync.hasValue ? _filterLostPersons(lostPersonsAsync.value!) : []),
                  ]..sort((a, b) => _getItemDistance(a).compareTo(_getItemDistance(b))),
                )
              : _mapCategory == 'Ghats' 
                ? ghatsAsync.when(
                    loading: () => const SizedBox(),
                    error: (error, stackTrace) => const SizedBox(),
                    data: (ghats) => _buildDraggableBottomSheet(
                      context,
                      isDark,
                      _filterGhats(ghats),
                    ),
                  )
                : _mapCategory == 'Facilities'
                  ? facilitiesAsync.when(
                      loading: () => const SizedBox(),
                      error: (error, stackTrace) => const SizedBox(),
                      data: (facilities) => _buildDraggableBottomSheetFacilities(
                        context,
                        isDark,
                        _filterFacilities(facilities),
                      ),
                    )
                  : lostPersonsAsync.when(
                      loading: () => const SizedBox(),
                      error: (error, stackTrace) => const SizedBox(),
                      data: (lost) => _buildDraggableBottomSheetLost(
                        context,
                        isDark,
                        _filterLostPersons(lost),
                      ),
                    ),
          ),

          // Layer 3: Floating Header (Always on top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildFloatingHeader(context, isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLayer(
    BuildContext context,
    bool isDark,
    AsyncValue<List<Ghat>> ghatsAsync,
    AsyncValue<List<Facility>> facilitiesAsync,
    AsyncValue<List<LostPerson>> lostPersonsAsync,
  ) {
    return Stack(
      children: [
        // The Map
        _buildMapBase(context, isDark, ghatsAsync, facilitiesAsync, lostPersonsAsync),

        // Map Controls
        Positioned(
          right: 16,
          bottom: 240,
          child: _buildMapControls(context, isDark, ref),
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
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.15, 0.45, 0.85],
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
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
                  ],
                ),
              ),
              if (ghats.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No ghats match your filter',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GhatCard(
                            ghat: ghats[index],
                            onNavigate: () {
                              _startNavigation(
                                context,
                                ref,
                                LatLng(ghats[index].latitude, ghats[index].longitude),
                                name: ghats[index].name,
                              );
                            },
                          ),
                        );
                      },
                      childCount: ghats.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableBottomSheetFacilities(
    BuildContext context,
    bool isDark,
    List<Facility> facilities,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.15, 0.45, 0.85],
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
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Facilities',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '${facilities.length} found',
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
                  ],
                ),
              ),
              if (facilities.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No facilities match your search',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FacilityCard(
                            facility: facilities[index],
                            onTap: () {
                              FacilityDetailSheet.show(context, facilities[index]);
                            },
                          ),
                        );
                      },
                      childCount: facilities.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableBottomSheetAll(
    BuildContext context,
    bool isDark,
    List<dynamic> items,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.15, 0.45, 0.85],
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
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Places',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '${items.length} found',
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
                  ],
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No places match your search',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final dynamic item = items[index];
                        
                        if (item is Ghat) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GhatCard(
                              ghat: item,
                              onNavigate: () {
                                _startNavigation(
                                  context,
                                  ref,
                                  LatLng(item.latitude, item.longitude),
                                  name: item.name,
                                );
                              },
                            ),
                          );
                        } else if (item is Facility) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FacilityCard(
                              facility: item,
                              onTap: () {
                                FacilityDetailSheet.show(context, item);
                              },
                            ),
                          );
                        } else if (item is LostPerson) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                subtitle: Text('Lost at: ${item.lastSeenLocation}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () {
                                  if (item.lastSeenLat != null) {
                                    ref.read(mapProvider.notifier).setCenter(LatLng(item.lastSeenLat!, item.lastSeenLng!));
                                  }
                                },
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableBottomSheetLost(
    BuildContext context,
    bool isDark,
    List<LostPerson> lost,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.15, 0.45, 0.85],
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
          child: CustomScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
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
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lost Persons',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '${lost.length} active cases',
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
                  ],
                ),
              ),
              if (lost.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No reports match your filter',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                lost[index].name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              subtitle: Text('Last seen: ${lost[index].lastSeenLocation}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () {
                                if (lost[index].lastSeenLat != null) {
                                  ref.read(mapProvider.notifier).setCenter(LatLng(lost[index].lastSeenLat!, lost[index].lastSeenLng!));
                                }
                              },
                            ),
                          ),
                        );
                      },
                      childCount: lost.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
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
                        color: (isDark
                                ? AppColors.backgroundDark
                                : Colors.white)
                            .withValues(alpha: 0.5),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.cardDark : Colors.white)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _mapCategory == 'All'
                            ? 'Search All...'
                            : (_mapCategory == 'Ghats'
                                ? 'Search Ghats...'
                                : 'Search Facilities...'),
                        hintStyle: TextStyle(
                          color: (isDark
                                  ? AppColors.textDarkDark
                                  : AppColors.textDarkLight)
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.search,
                          color: isDark
                              ? AppColors.textDarkDark
                              : AppColors.textDarkLight,
                          size: 22,
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDark
                                      ? AppColors.textDarkDark
                                      : AppColors.textDarkLight,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
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
                ),
                const SizedBox(width: 8),
                MenuAnchor(
                  builder: (context, controller, child) {
                    return GestureDetector(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.cardDark : Colors.white).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _mapCategory == 'All'
                                  ? Icons.map
                                  : (_mapCategory == 'Ghats'
                                      ? Icons.water
                                      : (_mapCategory == 'Facilities'
                                          ? Icons.place
                                          : Icons.person_search)),
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _mapCategory,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                  menuChildren: [
                    // --- ALL ---
                    MenuItemButton(
                      onPressed: () {
                        setState(() {
                          _mapCategory = 'All';
                          _selectedFilter = 'All Ghats';
                          _selectedFacilityType = null;
                        });
                      },
                      child: _buildMenuItem('All', Icons.map, 'All', true),
                    ),

                    // --- GHATS ---
                    SubmenuButton(
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              _mapCategory = 'Ghats';
                              _selectedFilter = 'All Ghats';
                              _selectedFacilityType = null;
                            });
                          },
                          child: _buildSubMenuItem('All Ghats', _mapCategory == 'Ghats' && _selectedFilter == 'All Ghats'),
                        ),
                        ..._filters.where((f) => f != 'All Ghats').map((filter) => MenuItemButton(
                          onPressed: () {
                            setState(() {
                              _mapCategory = 'Ghats';
                              _selectedFilter = filter;
                              _selectedFacilityType = null;
                            });
                          },
                          child: _buildSubMenuItem(filter, _mapCategory == 'Ghats' && _selectedFilter == filter),
                        )),
                      ],
                      child: _buildMenuItem('Ghats', Icons.water, 'Ghats', true),
                    ),

                    // --- FACILITIES ---
                    SubmenuButton(
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () {
                            setState(() {
                              _mapCategory = 'Facilities';
                              _selectedFilter = 'All Ghats';
                              _selectedFacilityType = null;
                            });
                          },
                          child: _buildSubMenuItem('All Facilities', _mapCategory == 'Facilities' && _selectedFacilityType == null),
                        ),
                        ...FacilityType.values.map((type) => MenuItemButton(
                          onPressed: () {
                            setState(() {
                              _mapCategory = 'Facilities';
                              _selectedFilter = 'All Ghats';
                              _selectedFacilityType = type;
                            });
                          },
                          child: _buildSubMenuItem(type.displayName, _mapCategory == 'Facilities' && _selectedFacilityType == type),
                        )),
                      ],
                      child: _buildMenuItem('Facilities', Icons.place, 'Facilities', true),
                    ),

                    // --- LOST PERSONS ---
                    MenuItemButton(
                      onPressed: () {
                        setState(() {
                          _mapCategory = 'Lost Persons';
                          _selectedFilter = 'All Ghats';
                          _selectedFacilityType = null;
                        });
                      },
                      child: _buildMenuItem('Lost Persons', Icons.person_search, 'Lost Persons', true),
                    ),
                  ],
                ),
              ],
            ),
            if ((_mapCategory == 'Ghats' || _mapCategory == 'All') &&
                _selectedFilter != 'All Ghats') ...[
              const SizedBox(height: 12),
              _buildActiveFilterTag(
                _selectedFilter,
                Icons.filter_list,
                isDark,
                () => setState(() => _selectedFilter = 'All Ghats'),
              ),
            ],
            if ((_mapCategory == 'Facilities' || _mapCategory == 'All') &&
                _selectedFacilityType != null) ...[
              const SizedBox(height: 12),
              _buildActiveFilterTag(
                _selectedFacilityType!.displayName,
                _getFacilityIcon(_selectedFacilityType!),
                isDark,
                () => setState(() => _selectedFacilityType = null),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFacilityIcon(FacilityType type) {
    switch (type) {
      case FacilityType.chargingPoint: return Icons.battery_charging_full;
      case FacilityType.washroom: return Icons.wc;
      case FacilityType.medical: return Icons.local_hospital;
      case FacilityType.food: return Icons.restaurant;
      case FacilityType.police: return Icons.local_police;
      case FacilityType.helpDesk: return Icons.help;
      case FacilityType.parking: return Icons.local_parking;
      case FacilityType.drinkingWater: return Icons.water_drop;
      case FacilityType.hotel: return Icons.hotel;
      case FacilityType.other: return Icons.place;
    }
  }

  Widget _buildMenuItem(String title, IconData icon, String value, bool isMain) {
    bool isSelected = _mapCategory == value;
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.primaryBlue : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : (isMain ? FontWeight.w600 : FontWeight.normal),
            color: isSelected ? AppColors.primaryBlue : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSubMenuItem(String title, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryBlue : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildActiveFilterTag(String label, IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
  Widget _buildMapBase(
    BuildContext context,
    bool isDark,
    AsyncValue<List<Ghat>> ghatsAsync,
    AsyncValue<List<Facility>> facilitiesAsync,
    AsyncValue<List<LostPerson>> lostPersonsAsync,
  ) {
    final locationState = ref.watch(locationProvider);
    final mapState = ref.watch(mapProvider);
    final routingState = ref.watch(routingProvider);

    // Get user location
    final userLocation = locationState.currentPosition != null
        ? LatLng(
            locationState.currentPosition!.latitude,
            locationState.currentPosition!.longitude,
          )
        : null;

    // Build markers dynamically based on the category
    final List<CustomMapMarker> markers = [];

    if (_mapCategory == 'Ghats' || _mapCategory == 'All') {
      ghatsAsync.whenData((ghats) {
        markers.addAll(_filterGhats(ghats).map((ghat) {
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
        }));
      });
    }

    if (_mapCategory == 'Facilities' || _mapCategory == 'All') {
      facilitiesAsync.whenData((facilities) {
        markers.addAll(_filterFacilities(facilities).map((facility) {
          IconData iconData = Icons.place;
          switch (facility.type) {
            case FacilityType.chargingPoint:
              iconData = Icons.battery_charging_full;
              break;
            case FacilityType.washroom:
              iconData = Icons.wc;
              break;
            case FacilityType.medical:
              iconData = Icons.local_hospital;
              break;
            case FacilityType.food:
              iconData = Icons.restaurant;
              break;
            case FacilityType.police:
              iconData = Icons.local_police;
              break;
            case FacilityType.helpDesk:
              iconData = Icons.help;
              break;
            case FacilityType.parking:
              iconData = Icons.local_parking;
              break;
            case FacilityType.drinkingWater:
              iconData = Icons.water_drop;
              break;
            case FacilityType.hotel:
              iconData = Icons.hotel;
              break;
            case FacilityType.other:
              iconData = Icons.place;
              break;
          }
          return CustomMapMarker.facility(
            id: facility.id,
            position: LatLng(facility.latitude, facility.longitude),
            name: facility.name,
            icon: iconData,
            metadata: {'facility': facility},
          );
        }));
      });
    }

    if (_mapCategory == 'Lost Persons' || _mapCategory == 'All') {
      lostPersonsAsync.whenData((lost) {
        markers.addAll(_filterLostPersons(lost).where((p) => p.lastSeenLat != null).map((person) {
          return CustomMapMarker(
            id: person.id,
            type: MapMarkerType.emergency,
            position: LatLng(person.lastSeenLat!, person.lastSeenLng!),
            title: 'Lost: ${person.name}',
            icon: Icons.person_search,
            color: Colors.orange,
            isPulsing: true,
            metadata: {'lost_person': person},
          );
        }));
      });
    }

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
        
        // Show facility details
        if (marker.metadata != null && marker.metadata!['facility'] != null) {
          FacilityDetailSheet.show(context, marker.metadata!['facility'] as Facility);
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
      ],
    );
  }
}
