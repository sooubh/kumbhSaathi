import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../data/models/facility_route.dart';

/// Service for tracking user location during route recording
class LocationTrackingService {
  StreamSubscription<Position>? _positionStream;
  final List<RoutePoint> _recordedPoints = [];
  DateTime? _startTime;
  double _totalDistance = 0.0;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Start recording route
  Future<void> startRecording() async {
    // Check permissions
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    // Check if location service is enabled
    if (!await isLocationServiceEnabled()) {
      throw Exception('Location services are disabled');
    }

    // Clear previous data
    _recordedPoints.clear();
    _totalDistance = 0.0;
    _startTime = DateTime.now();

    // Start listening to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _addPoint(position);
          },
        );
  }

  /// Add a position point to the route
  void _addPoint(Position position) {
    final point = RoutePoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );

    // Calculate distance from last point
    if (_recordedPoints.isNotEmpty) {
      final lastPoint = _recordedPoints.last;
      final distance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        point.latitude,
        point.longitude,
      );
      _totalDistance += distance;
    }

    _recordedPoints.add(point);
  }

  /// Stop recording and return the recorded route data
  Future<RouteData> stopRecording() async {
    await _positionStream?.cancel();
    _positionStream = null;

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;

    return RouteData(
      points: List.from(_recordedPoints),
      distanceMeters: _totalDistance,
      durationMinutes: duration.inMinutes,
    );
  }

  /// Get current recording status
  bool get isRecording => _positionStream != null;

  /// Get current route points
  List<RoutePoint> get currentPoints => List.from(_recordedPoints);

  /// Get current distance
  double get currentDistance => _totalDistance;

  /// Get current duration in minutes
  int get currentDurationMinutes {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inMinutes;
  }

  /// Dispose resources
  void dispose() {
    _positionStream?.cancel();
    _positionStream = null;
    _recordedPoints.clear();
  }
}

/// Data class for recorded route
class RouteData {
  final List<RoutePoint> points;
  final double distanceMeters;
  final int durationMinutes;

  RouteData({
    required this.points,
    required this.distanceMeters,
    required this.durationMinutes,
  });
}
