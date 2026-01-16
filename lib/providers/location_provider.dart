import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/services/firestore_location_service.dart';
import '../data/models/user_location_model.dart';

/// Location state with when-like functionality
class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;

  LocationState({this.currentPosition, this.isLoading = false, this.error});

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Helper method similar to AsyncValue.when
  T when<T>({
    required T Function() loading,
    required T Function(Object error, StackTrace stackTrace) error,
    required T Function(Position? position) data,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error!, StackTrace.current);
    } else {
      return data(currentPosition);
    }
  }

  /// Get position or null
  Position? get valueOrNull => currentPosition;
}

/// Location state notifier
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    // Auto-fetch location on init
    getCurrentLocation();
  }

  bool _isStreamingToFirestore = false;
  final FirestoreLocationService _firestoreService = FirestoreLocationService();

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(error: 'Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(error: 'Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(error: 'Location permission permanently denied');
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    // Request permission first
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      state = state.copyWith(currentPosition: position, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get location: $e',
      );
    }
  }

  void startLocationStream() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      state = state.copyWith(currentPosition: position);
    });
  }

  /// Start streaming location to Firestore for realtime sharing
  Future<void> startFirestoreLocationSync({
    required String userId,
    required String userName,
  }) async {
    if (_isStreamingToFirestore) return;

    _isStreamingToFirestore = true;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) async {
      state = state.copyWith(currentPosition: position);

      // Update Firestore
      try {
        final userLocation = UserLocation(
          userId: userId,
          userName: userName,
          position: LatLng(position.latitude, position.longitude),
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
          isSharing: true,
          status: _determineStatus(position.speed),
        );

        await _firestoreService.updateUserLocation(userLocation);
      } catch (e) {
        // Silently fail - don't disrupt location tracking
      }
    });
  }

  /// Stop streaming location to Firestore
  Future<void> stopFirestoreLocationSync(String userId) async {
    _isStreamingToFirestore = false;
    try {
      await _firestoreService.deleteUserLocation(userId);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Update sharing status
  Future<void> updateSharingStatus({
    required String userId,
    required bool isSharing,
  }) async {
    try {
      await _firestoreService.updateSharingStatus(
        userId: userId,
        isSharing: isSharing,
      );
    } catch (e) {
      // Ignore errors
    }
  }

  String _determineStatus(double speed) {
    if (speed < 0.5) return 'stationary';
    if (speed < 2.0) return 'moving';
    return 'active';
  }
}

/// Location provider
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);
