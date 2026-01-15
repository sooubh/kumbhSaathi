import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Service for map-related calculations and utilities
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final Distance _distance = const Distance();

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Calculate distance in kilometers
  double calculateDistanceKm(LatLng point1, LatLng point2) {
    return calculateDistance(point1, point2) / 1000;
  }

  /// Calculate bearing/direction from point1 to point2
  /// Returns angle in degrees (0-360)
  double calculateBearing(LatLng point1, LatLng point2) {
    final lat1 = _degreesToRadians(point1.latitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final lon1 = _degreesToRadians(point1.longitude);
    final lon2 = _degreesToRadians(point2.longitude);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  /// Get compass direction from bearing
  String getCompassDirection(double bearing) {
    const directions = [
      'North', 'Northeast', 'East', 'Southeast',
      'South', 'Southwest', 'West', 'Northwest'
    ];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Calculate bounds for a list of points
  /// Returns [southwest, northeast] corners
  List<LatLng> calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return [
        LatLng(0, 0),
        LatLng(0, 0),
      ];
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return [
      LatLng(minLat, minLng), // Southwest
      LatLng(maxLat, maxLng), // Northeast
    ];
  }

  /// Calculate center point from a list of points
  LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLng(0, 0);
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }

  /// Calculate appropriate zoom level for given bounds and map size
  /// mapWidthPx and mapHeightPx are the map dimensions in pixels
  double calculateZoomLevel({
    required LatLng southwest,
    required LatLng northeast,
    required double mapWidthPx,
    required double mapHeightPx,
    double padding = 50,
  }) {
    const worldWidthPx = 256.0; // At zoom level 0

    final latDiff = (northeast.latitude - southwest.latitude).abs();
    final lngDiff = (northeast.longitude - southwest.longitude).abs();

    // Calculate zoom level based on longitude difference
    final lngZoom = math.log(((mapWidthPx - 2 * padding) * 360) / (lngDiff * worldWidthPx)) / math.ln2;

    // Calculate zoom level based on latitude difference
    final latRad1 = _degreesToRadians(southwest.latitude);
    final latRad2 = _degreesToRadians(northeast.latitude);
    final latFraction = (latRad2 - latRad1) / math.pi;
    final latZoom = math.log((mapHeightPx - 2 * padding) / (worldWidthPx * latFraction)) / math.ln2;

    // Return the smaller zoom level to fit everything
    return math.min(lngZoom, latZoom).clamp(1.0, 18.0);
  }

  /// Estimate walking time in seconds for a given distance in meters
  /// Assumes average walking speed of 5 km/h
  int estimateWalkingTime(double distanceMeters, {double speedKmh = 5.0}) {
    final distanceKm = distanceMeters / 1000;
    final hours = distanceKm / speedKmh;
    return (hours * 3600).round();
  }

  /// Check if a point is within a certain radius of another point
  bool isWithinRadius({
    required LatLng center,
    required LatLng point,
    required double radiusMeters,
  }) {
    final distance = calculateDistance(center, point);
    return distance <= radiusMeters;
  }

  /// Get points within a certain radius
  List<T> getPointsWithinRadius<T>({
    required LatLng center,
    required List<T> points,
    required LatLng Function(T) getPosition,
    required double radiusMeters,
  }) {
    return points.where((point) {
      final position = getPosition(point);
      return isWithinRadius(
        center: center,
        point: position,
        radiusMeters: radiusMeters,
      );
    }).toList();
  }

  /// Sort points by distance from a center point
  List<T> sortByDistance<T>({
    required LatLng center,
    required List<T> points,
    required LatLng Function(T) getPosition,
  }) {
    final pointsWithDistance = points.map((point) {
      final position = getPosition(point);
      final distance = calculateDistance(center, position);
      return {'point': point, 'distance': distance};
    }).toList();

    pointsWithDistance.sort((a, b) =>
        (a['distance'] as double).compareTo(b['distance'] as double));

    return pointsWithDistance.map((item) => item['point'] as T).toList();
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }
}
