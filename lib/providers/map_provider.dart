import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/config/panchavati_config.dart';
import '../data/models/map_marker_model.dart';
import '../data/models/route_model.dart';

/// Map state
class MapState {
  final LatLng center;
  final double zoom;
  final List<CustomMapMarker> markers;
  final NavigationRoute? activeRoute;
  final CustomMapMarker? selectedMarker;
  final bool isTracking; // Following user location
  final bool showTraffic;
  final bool showSatellite;

  MapState({
    required this.center,
    this.zoom = 13.0,
    this.markers = const [],
    this.activeRoute,
    this.selectedMarker,
    this.isTracking = false,
    this.showTraffic = false,
    this.showSatellite = false,
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    List<CustomMapMarker>? markers,
    NavigationRoute? activeRoute,
    bool clearRoute = false,
    CustomMapMarker? selectedMarker,
    bool clearSelectedMarker = false,
    bool? isTracking,
    bool? showTraffic,
    bool? showSatellite,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      markers: markers ?? this.markers,
      activeRoute: clearRoute ? null : (activeRoute ?? this.activeRoute),
      selectedMarker: clearSelectedMarker
          ? null
          : (selectedMarker ?? this.selectedMarker),
      isTracking: isTracking ?? this.isTracking,
      showTraffic: showTraffic ?? this.showTraffic,
      showSatellite: showSatellite ?? this.showSatellite,
    );
  }
}

/// Map state notifier
class MapNotifier extends StateNotifier<MapState> {
  MapNotifier()
    : super(
        MapState(
          center: PanchavatiConfig.panchavatiCenter,
          zoom: PanchavatiConfig.optimalZoom,
        ),
      );

  void setCenter(LatLng center) {
    state = state.copyWith(center: center);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void zoomIn() {
    state = state.copyWith(
      zoom: (state.zoom + 1).clamp(
        PanchavatiConfig.minZoom,
        PanchavatiConfig.maxZoom,
      ),
    );
  }

  void zoomOut() {
    state = state.copyWith(
      zoom: (state.zoom - 1).clamp(
        PanchavatiConfig.minZoom,
        PanchavatiConfig.maxZoom,
      ),
    );
  }

  void setMarkers(List<CustomMapMarker> markers) {
    state = state.copyWith(markers: markers);
  }

  void addMarker(CustomMapMarker marker) {
    final updatedMarkers = [...state.markers, marker];
    state = state.copyWith(markers: updatedMarkers);
  }

  void removeMarker(String markerId) {
    final updatedMarkers = state.markers
        .where((m) => m.id != markerId)
        .toList();
    state = state.copyWith(markers: updatedMarkers);
  }

  void setActiveRoute(NavigationRoute? route) {
    state = state.copyWith(activeRoute: route);
  }

  void clearRoute() {
    state = state.copyWith(clearRoute: true);
  }

  void selectMarker(CustomMapMarker? marker) {
    state = state.copyWith(selectedMarker: marker);
  }

  void clearSelectedMarker() {
    state = state.copyWith(clearSelectedMarker: true);
  }

  void setTracking(bool isTracking) {
    state = state.copyWith(isTracking: isTracking);
  }

  void toggleTracking() {
    state = state.copyWith(isTracking: !state.isTracking);
  }

  void toggleTraffic() {
    state = state.copyWith(showTraffic: !state.showTraffic);
  }

  void toggleSatellite() {
    state = state.copyWith(showSatellite: !state.showSatellite);
  }
}

/// Map provider
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
