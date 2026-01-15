import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/services/routing_service.dart';
import '../data/models/route_model.dart';

/// Routing state
class RoutingState {
  final LatLng? startPoint;
  final LatLng? endPoint;
  final String? startName;
  final String? endName;
  final NavigationRoute? calculatedRoute;
  final List<NavigationRoute>? alternativeRoutes;
  final bool isCalculating;
  final bool isNavigating;
  final String? error;
  final int? currentStepIndex;

  RoutingState({
    this.startPoint,
    this.endPoint,
    this.startName,
    this.endName,
    this.calculatedRoute,
    this.alternativeRoutes,
    this.isCalculating = false,
    this.isNavigating = false,
    this.error,
    this.currentStepIndex,
  });

  bool get hasRoute => calculatedRoute != null;
  bool get canCalculate => startPoint != null && endPoint != null;

  RoutingState copyWith({
    LatLng? startPoint,
    LatLng? endPoint,
    String? startName,
    String? endName,
    NavigationRoute? calculatedRoute,
    List<NavigationRoute>? alternativeRoutes,
    bool? isCalculating,
    bool? isNavigating,
    String? error,
    int? currentStepIndex,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearRoute = false,
    bool clearError = false,
  }) {
    return RoutingState(
      startPoint: clearStart ? null : (startPoint ?? this.startPoint),
      endPoint: clearEnd ? null : (endPoint ?? this.endPoint),
      startName: clearStart ? null : (startName ?? this.startName),
      endName: clearEnd ? null : (endName ?? this.endName),
      calculatedRoute:
          clearRoute ? null : (calculatedRoute ?? this.calculatedRoute),
      alternativeRoutes:
          clearRoute ? null : (alternativeRoutes ?? this.alternativeRoutes),
      isCalculating: isCalculating ?? this.isCalculating,
      isNavigating: isNavigating ?? this.isNavigating,
      error: clearError ? null : (error ?? this.error),
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    );
  }
}

/// Routing state notifier
class RoutingNotifier extends StateNotifier<RoutingState> {
  RoutingNotifier() : super(RoutingState());

  final RoutingService _routingService = RoutingService();

  void setStartPoint(LatLng point, {String? name}) {
    state = state.copyWith(startPoint: point, startName: name);
  }

  void setEndPoint(LatLng point, {String? name}) {
    state = state.copyWith(endPoint: point, endName: name);
  }

  void clearStart() {
    state = state.copyWith(clearStart: true);
  }

  void clearEnd() {
    state = state.copyWith(clearEnd: true);
  }

  void clearRoute() {
    state = state.copyWith(
      clearRoute: true,
      isNavigating: false,
      currentStepIndex: null,
    );
  }

  void swapPoints() {
    state = state.copyWith(
      startPoint: state.endPoint,
      endPoint: state.startPoint,
      startName: state.endName,
      endName: state.startName,
      clearRoute: true,
    );
  }

  Future<void> calculateRoute() async {
    if (!state.canCalculate) {
      state = state.copyWith(
        error: 'Please set both start and end points',
        clearError: false,
      );
      return;
    }

    state = state.copyWith(
      isCalculating: true,
      clearError: true,
      clearRoute: true,
    );

    try {
      final route = await _routingService.calculateRoute(
        start: state.startPoint!,
        end: state.endPoint!,
        startName: state.startName,
        endName: state.endName,
      );

      state = state.copyWith(
        calculatedRoute: route,
        isCalculating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isCalculating: false,
        error: 'Failed to calculate route: $e',
      );
    }
  }

  Future<void> calculateAlternativeRoutes() async {
    if (!state.canCalculate) return;

    state = state.copyWith(isCalculating: true, clearError: true);

    try {
      final routes = await _routingService.calculateAlternativeRoutes(
        start: state.startPoint!,
        end: state.endPoint!,
        startName: state.startName,
        endName: state.endName,
        numAlternatives: 2,
      );

      state = state.copyWith(
        calculatedRoute: routes.isNotEmpty ? routes[0] : null,
        alternativeRoutes: routes,
        isCalculating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isCalculating: false,
        error: 'Failed to calculate routes: $e',
      );
    }
  }

  void selectAlternativeRoute(int index) {
    if (state.alternativeRoutes != null &&
        index < state.alternativeRoutes!.length) {
      state = state.copyWith(
        calculatedRoute: state.alternativeRoutes![index],
      );
    }
  }

  void startNavigation() {
    if (state.calculatedRoute != null) {
      state = state.copyWith(
        isNavigating: true,
        currentStepIndex: 0,
      );
    }
  }

  void stopNavigation() {
    state = state.copyWith(
      isNavigating: false,
      currentStepIndex: null,
    );
  }

  void nextStep() {
    if (state.isNavigating &&
        state.calculatedRoute != null &&
        state.currentStepIndex != null) {
      final nextIndex = state.currentStepIndex! + 1;
      if (nextIndex < state.calculatedRoute!.steps.length) {
        state = state.copyWith(currentStepIndex: nextIndex);
      } else {
        // Reached destination
        stopNavigation();
      }
    }
  }

  void previousStep() {
    if (state.isNavigating &&
        state.currentStepIndex != null &&
        state.currentStepIndex! > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex! - 1);
    }
  }

  RouteStep? get currentStep {
    if (state.calculatedRoute != null && state.currentStepIndex != null) {
      return state.calculatedRoute!.steps[state.currentStepIndex!];
    }
    return null;
  }
}

/// Routing provider
final routingProvider =
    StateNotifierProvider<RoutingNotifier, RoutingState>((ref) {
  return RoutingNotifier();
});
