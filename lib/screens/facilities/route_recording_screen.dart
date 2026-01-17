import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/location_tracking_service.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/facility.dart';
import '../../data/models/facility_route.dart';
import '../../data/repositories/facility_route_repository.dart';
import '../../widgets/common/primary_button.dart';

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
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  bool _isRecording = false;
  bool _isSubmitting = false;
  Timer? _updateTimer;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(widget.facility.id),
          position: LatLng(widget.facility.latitude, widget.facility.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: widget.facility.name),
        ),
      };
    });
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
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          color: AppColors.primaryBlue,
          width: 5,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        ),
      };
    });

    // Auto-center map on latest position
    if (points.isNotEmpty) {
      _controllerCompleter.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(points.last.latitude, points.last.longitude),
          ),
        );
      });
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

      // Create route object
      final route = FacilityRoute(
        id: '',
        facilityId: widget.facility.id,
        userId: userId,
        userName: 'User', // TODO: Get from user profile
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: const Text('Record Route'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.facility.latitude,
                widget.facility.longitude,
              ),
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _controllerCompleter.complete(controller);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
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
                  color: AppColors.primaryBlue.withOpacity(0.9),
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
                        color: Colors.white.withOpacity(0.9),
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
