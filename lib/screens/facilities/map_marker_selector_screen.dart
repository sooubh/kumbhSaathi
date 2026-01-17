import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/primary_button.dart';

/// Interactive map screen for selecting exact facility location
class MapMarkerSelectorScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const MapMarkerSelectorScreen({
    super.key,
    this.initialPosition,
    this.initialAddress,
  });

  @override
  State<MapMarkerSelectorScreen> createState() =>
      _MapMarkerSelectorScreenState();
}

class _MapMarkerSelectorScreenState extends State<MapMarkerSelectorScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  LatLng? _selectedPosition;
  String _selectedAddress = 'Fetching address...';
  bool _isLoading = true;
  bool _isFetchingAddress = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Use provided position or get current location
      if (widget.initialPosition != null) {
        _selectedPosition = widget.initialPosition;
        if (widget.initialAddress != null) {
          _selectedAddress = widget.initialAddress!;
        } else {
          await _getAddressFromLatLng(_selectedPosition!);
        }
      } else {
        await _getCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
      // Default to Nashik Kumbh area if location fails
      _selectedPosition = const LatLng(20.0062, 73.7892);
      _selectedAddress = 'Nashik, Maharashtra';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _selectedPosition = LatLng(position.latitude, position.longitude);
    await _getAddressFromLatLng(_selectedPosition!);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isFetchingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress = [
            if (place.name != null && place.name!.isNotEmpty) place.name,
            if (place.subLocality != null && place.subLocality!.isNotEmpty)
              place.subLocality,
            if (place.locality != null && place.locality!.isNotEmpty)
              place.locality,
          ].join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } finally {
      setState(() => _isFetchingAddress = false);
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() => _selectedPosition = position);
    _getAddressFromLatLng(position);
  }

  void _onConfirmLocation() {
    if (_selectedPosition != null) {
      Navigator.pop(context, {
        'position': _selectedPosition,
        'address': _selectedAddress,
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPosition = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPosition = newPosition);
      await _getAddressFromLatLng(newPosition);

      final controller = await _controllerCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
            tooltip: 'Current Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition!,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _controllerCompleter.complete(controller);
            },
            onTap: _onMapTapped,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedPosition!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() => _selectedPosition = newPosition);
                        _getAddressFromLatLng(newPosition);
                      },
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Address Info Card
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        if (_isFetchingAddress) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedPosition!.latitude.toStringAsFixed(6)}, ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap or drag marker to select exact location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: PrimaryButton(
              text: 'CONFIRM LOCATION',
              onPressed: _onConfirmLocation,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
}
