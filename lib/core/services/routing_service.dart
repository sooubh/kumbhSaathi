import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/route_model.dart';
import 'map_service.dart';

/// A* pathfinding service for route calculation
class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  final MapService _mapService = MapService();

  /// Calculate route using OSRM Foot Profile API
  Future<NavigationRoute> calculateRoute({
    required LatLng start,
    required LatLng end,
    String? startName,
    String? endName,
    List<LatLng>? viaPoints,
  }) async {
    String coords = '${start.longitude},${start.latitude}';
    if (viaPoints != null) {
      for (var point in viaPoints) {
        coords += ';${point.longitude},${point.latitude}';
      }
    }
    coords += ';${end.longitude},${end.latitude}';

    final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/foot/$coords?overview=full&geometries=polyline&steps=true');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Routing API returned ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
        throw Exception('No paths available');
      }

      final routeData = data['routes'][0];
      final geometry = routeData['geometry'] as String;
      final distance = (routeData['distance'] as num).toDouble();
      final duration = (routeData['duration'] as num).toInt();
      
      final points = _decodePolyline(geometry);
      if (points.length <= 1) {
        throw Exception('Invalid path generated');
      }

      final waypoints = points.map((p) => RoutePoint(position: p)).toList();
      waypoints.first = RoutePoint(position: points.first, name: startName);
      waypoints.last = RoutePoint(position: points.last, name: endName);

      final steps = <RouteStep>[];
      final legs = routeData['legs'] as List;
      for (var leg in legs) {
        final legSteps = leg['steps'] as List;
        for (var step in legSteps) {
          final maneuver = step['maneuver'];
          final location = maneuver['location'] as List;
          steps.add(RouteStep(
            instruction: step['name'] != null && step['name'].toString().isNotEmpty 
                ? '${maneuver['type']} on ${step['name']}' 
                : '${maneuver['type']}',
            distanceMeters: (step['distance'] as num).toDouble(),
            durationSeconds: (step['duration'] as num).toInt(),
            position: LatLng(location[1], location[0]),
            direction: (maneuver['modifier'] ?? 'straight').toString(),
          ));
        }
      }

      return NavigationRoute(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        start: start,
        end: end,
        waypoints: waypoints,
        steps: steps,
        totalDistanceMeters: distance,
        totalDurationSeconds: duration,
        createdAt: DateTime.now(),
        startName: startName,
        endName: endName,
      );

    } catch (e) {
      throw Exception('Route unavailable: $e');
    }
  }

  /// Decode Google Polyline format
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Calculate multiple alternative routes
  Future<List<NavigationRoute>> calculateAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    String? startName,
    String? endName,
    int numAlternatives = 2,
  }) async {
    final routes = <NavigationRoute>[];

    // Primary route (straight)
    final primaryRoute = await calculateRoute(
      start: start,
      end: end,
      startName: startName,
      endName: endName,
    );
    routes.add(primaryRoute);

    // Alternative routes with different via points
    for (int i = 0; i < numAlternatives; i++) {
      // Create a slight deviation point
      final midpoint = LatLng(
        (start.latitude + end.latitude) / 2,
        (start.longitude + end.longitude) / 2,
      );

      // Offset the midpoint slightly
      final offset = (i + 1) * 0.001; // ~100m offset
      final viaPoint = LatLng(
        midpoint.latitude + offset,
        midpoint.longitude + offset * (i % 2 == 0 ? 1 : -1),
      );

      final altRoute = await calculateRoute(
        start: start,
        end: end,
        startName: startName,
        endName: endName,
        viaPoints: [viaPoint],
      );

      routes.add(altRoute);
    }

    return routes;
  }

}
