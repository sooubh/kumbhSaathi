import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/firebase_service.dart';
import '../core/services/notification_service.dart';
import '../data/repositories/emergency_repository.dart';
import '../core/services/family_group_service.dart';
import '../core/utils/auth_helper.dart';
import 'location_provider.dart';
import 'package:geolocator/geolocator.dart';

class SOSState {
  final bool isActive;
  final bool isLoading;
  final String? alertId;
  final String? error;

  SOSState({
    this.isActive = false,
    this.isLoading = false,
    this.alertId,
    this.error,
  });

  SOSState copyWith({
    bool? isActive,
    bool? isLoading,
    String? alertId,
    String? error,
    bool clearError = false,
  }) {
    return SOSState(
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      alertId: alertId ?? this.alertId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SOSNotifier extends StateNotifier<SOSState> {
  final Ref ref;
  final EmergencyRepository _repository = EmergencyRepository();

  SOSNotifier(this.ref) : super(SOSState());

  /// Activate SOS session
  Future<void> activateSOS() async {
    if (state.isActive || state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final userId = FirebaseService.currentUserId ?? 'anonymous';
      final userName = await AuthHelper.getUserFullName();

      // 1. Get initial location from provider
      final locationAsync = ref.read(locationProvider);
      Position? position = locationAsync.valueOrNull;

      // 2. Add alert to Firestore
      final alertId = await _repository.sendSOSAlert(
        userId: userId,
        userName: userName,
        latitude: position?.latitude ?? 20.0063,
        longitude: position?.longitude ?? 73.7897,
        locationDescription: 'Lat: ${position?.latitude}, Lng: ${position?.longitude}',
      );

      // 3. Start live location syncing to family map
      await ref.read(locationProvider.notifier).startFirestoreLocationSync(
        userId: userId,
        userName: userName,
      );

      // 4. Send Firebase Push Notification to family groups
      final familyGroupsStream = FamilyGroupService().streamUserGroups();
      final familyGroups = await familyGroupsStream.first;
      for (final group in familyGroups) {
        await NotificationService().sendSOSNotification(
          topic: 'sos_${group.groupId}',
          senderName: userName,
          alertId: alertId,
        );
      }

      // 5. Send Notification to Mela Authorities
      await NotificationService().sendSOSNotification(
        topic: 'sos_authorities',
        senderName: userName,
        alertId: alertId,
      );

      state = state.copyWith(
        isActive: true,
        isLoading: false,
        alertId: alertId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to activate SOS: $e',
      );
    }
  }

  /// Cancel Active SOS
  Future<void> cancelSOS() async {
    if (state.alertId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final userId = FirebaseService.currentUserId ?? 'anonymous';

      // 1. Cancel in Firestore
      await _repository.cancelAlert(state.alertId!);

      // 2. Stop live location syncing
      await ref.read(locationProvider.notifier).stopFirestoreLocationSync(userId);

      state = SOSState(); // Reset
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel SOS: $e',
      );
    }
  }

  /// Mark SOS as resolved
  Future<void> resolveSOS(String resolvedBy) async {
    if (state.alertId == null) return;
    
    state = state.copyWith(isLoading: true);

    try {
      final userId = FirebaseService.currentUserId ?? 'anonymous';
      
      // 1. Resolve in Firestore
      await _repository.resolveAlert(state.alertId!, resolvedBy);

      // 2. Stop live location syncing
      await ref.read(locationProvider.notifier).stopFirestoreLocationSync(userId);

      state = SOSState(); // Reset
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resolve SOS: $e',
      );
    }
  }
}

final sosProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  return SOSNotifier(ref);
});
