import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/map_marker_model.dart';
import '../../data/models/route_model.dart';
import '../../providers/map_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/panchavati_config.dart';
import 'custom_marker_widget.dart';

/// Reusable map widget with OpenStreetMap tiles
class MapWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<CustomMapMarker> markers;
  final NavigationRoute? route;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final Function(CustomMapMarker)? onMarkerTap;
  final bool showUserLocation;
  final LatLng? userLocation;
  final bool enableInteraction;

  const MapWidget({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.markers = const [],
    this.route,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.showUserLocation = true,
    this.userLocation,
    this.enableInteraction = true,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-center map when center changes
    if (oldWidget.center != widget.center) {
      _mapController.move(widget.center, widget.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        onTap: widget.enableInteraction
            ? (tapPosition, point) => widget.onTap?.call(point)
            : null,
        onLongPress: widget.enableInteraction
            ? (tapPosition, point) => widget.onLongPress?.call(point)
            : null,
        interactionOptions: InteractionOptions(
          flags: widget.enableInteraction
              ? InteractiveFlag.all
              : InteractiveFlag.none,
        ),
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: isDark
              ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const [] : const ['a', 'b', 'c'],
          userAgentPackageName: 'com.kumbhsaathi.app',
          maxZoom: 19,
        ),

        // Panchavati Area Highlight
        PolygonLayer(
          polygons: [
            Polygon(
              points: PanchavatiConfig.panchavatiAreaBoundary,
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderColor: AppColors.primaryBlue.withValues(alpha: 0.5),
              borderStrokeWidth: 3,
              isFilled: true,
              label: 'Panchavati Area',
              labelStyle: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        // Main Pilgrimage Route (dotted line)
        PolylineLayer(
          polylines: [
            Polyline(
              points: PanchavatiConfig.mainPilgrimageRoute,
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
              strokeWidth: 2.0,
              isDotted: true,
            ),
          ],
        ),

        // Route polyline
        if (widget.route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route!.waypoints
                    .map((wp) => wp.position)
                    .toList(),
                color: AppColors.primaryBlue,
                strokeWidth: 4.0,
                borderColor: Colors.white,
                borderStrokeWidth: 2.0,
              ),
            ],
          ),

        // User location marker
        if (widget.showUserLocation && widget.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.userLocation!,
                width: 60,
                height: 60,
                child: CustomMarkerWidget(
                  marker: CustomMapMarker.userLocation(
                    userId: 'current_user',
                    position: widget.userLocation!,
                    userName: 'You',
                  ),
                  onTap: null,
                ),
              ),
            ],
          ),

        // Custom markers
        if (widget.markers.isNotEmpty)
          MarkerLayer(
            markers: widget.markers.map((marker) {
              return Marker(
                point: marker.position,
                width: 80,
                height: 80,
                child: CustomMarkerWidget(
                  marker: marker,
                  onTap: () => widget.onMarkerTap?.call(marker),
                ),
              );
            }).toList(),
          ),

        // Attribution
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
