import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/location_tracking_service.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/facility.dart';
import '../../data/models/facility_route.dart';
import '../../data/repositories/facility_route_repository.dart';
import '../../widgets/common/primary_button.dart';
import '../../core/utils/auth_helper.dart';

/// Screen for recording a walking route to a facility
class RouteRecordingScreen extends StatefulWidget {
  final Facility facility;

  const RouteRecordingScreen({super.key, required this.facility});

  @override
  State<RouteRecordingScreen> createState() => _RouteRecordingScreenState();
}

class _RouteRecordingScreenState extends State<RouteRecordingScreen> {
  final LocationTrackingService _trackingService = LocationTrackingService();
  final FacilityRouteRepository _repository = FacilityRouteRepository();
  final MapController _mapController = MapController();

  bool _isRecording = false;
  bool _isSubmitting = false;
  Timer? _updateTimer;
  List<LatLng> _polylinePoints = [];
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startRecording() async {
    try {
      await _trackingService.startRecording();
      setState(() => _isRecording = true);

      // Update UI every second
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          _updatePolyline();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started! Start walking to the facility.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  void _updatePolyline() {
    final points = _trackingService.currentPoints;
    if (points.isEmpty) return;

    setState(() {
      _polylinePoints = points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      if (points.isNotEmpty) {
        _currentLocation = LatLng(points.last.latitude, points.last.longitude);
      }
    });

    // Auto-center map on latest position
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16);
    }
  }

  Future<void> _stopAndSubmit() async {
    setState(() => _isSubmitting = true);
    _updateTimer?.cancel();

    try {
      final routeData = await _trackingService.stopRecording();

      if (routeData.points.length < 2) {
        throw Exception('Route too short. Please record a longer path.');
      }

      // Get user profile for name
      final userId = FirebaseService.currentUserId;
      if (userId == null) {
        throw Exception('Not logged in');
      }

      final userName = await AuthHelper.getUserFullName();

      // Create route object
      final route = FacilityRoute(
        id: '',
        facilityId: widget.facility.id,
        userId: userId,
        userName: userName,
        pathPoints: routeData.points,
        distanceMeters: routeData.distanceMeters,
        durationMinutes: routeData.durationMinutes,
        recordedAt: DateTime.now(),
        status: 'pending',
      );

      // Save to Firestore
      await _repository.saveRoute(route);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Route submitted for admin approval! Thank you for contributing.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isRecording = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _trackingService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final facilityLocation = LatLng(
      widget.facility.latitude,
      widget.facility.longitude,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: const Text('Record Route'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: facilityLocation,
              initialZoom: 15,
              minZoom: 10,
              maxZoom: 19,
            ),
            children: [
              // Tile Layer
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.kumbhsaathi.app',
                maxZoom: 19,
              ),

              // Route polyline
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints,
                      color: AppColors.primaryBlue,
                      strokeWidth: 5.0,
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),

              // Facility marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: facilityLocation,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primaryOrange,
                      size: 40,
                    ),
                  ),
                ],
              ),

              // Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Stats Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: isDark ? AppColors.cardDark : Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.facility.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Distance',
                          '${(_trackingService.currentDistance).toStringAsFixed(0)}m',
                          Icons.straighten,
                          isDark,
                        ),
                        _buildStatColumn(
                          'Duration',
                          '${_trackingService.currentDurationMinutes} min',
                          Icons.timer,
                          isDark,
                        ),
                        _buildStatColumn(
                          'Points',
                          '${_trackingService.currentPoints.length}',
                          Icons.location_on,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions/Status
          if (!_isRecording)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Press START to begin recording your route',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Walk to ${widget.facility.name} and we\'ll track your path',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Control Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _isRecording
                ? Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'I\'VE ARRIVED',
                          onPressed: _isSubmitting ? null : _stopAndSubmit,
                          isLoading: _isSubmitting,
                          backgroundColor: AppColors.success,
                          icon: Icons.check_circle,
                        ),
                      ),
                    ],
                  )
                : PrimaryButton(
                    text: 'START RECORDING',
                    onPressed: _startRecording,
                    icon: Icons.radio_button_checked,
                    backgroundColor: AppColors.primaryOrange,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }
}
