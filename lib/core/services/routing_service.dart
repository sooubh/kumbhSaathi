import 'dart:collection';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../../data/models/route_model.dart';
import 'map_service.dart';

/// A* pathfinding service for route calculation
class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  final MapService _mapService = MapService();

  /// Calculate route using A* algorithm
  /// For simple implementation, creates optimized waypoints with intermediate stops
  Future<NavigationRoute> calculateRoute({
    required LatLng start,
    required LatLng end,
    String? startName,
    String? endName,
    List<LatLng>? viaPoints,
  }) async {
    // For this implementation, we'll create an optimized walking route
    // In a full implementation, you'd use actual road network data

    final waypoints = <RoutePoint>[];
    final steps = <RouteStep>[];

    // Add start point
    waypoints.add(RoutePoint(
      position: start,
      name: startName,
    ));

    // If there are via points, add them
    if (viaPoints != null && viaPoints.isNotEmpty) {
      for (final point in viaPoints) {
        waypoints.add(RoutePoint(position: point));
      }
    }

    // Add end point
    waypoints.add(RoutePoint(
      position: end,
      name: endName,
    ));

    // Calculate steps between each waypoint pair
    double totalDistance = 0;
    int totalDuration = 0;

    for (int i = 0; i < waypoints.length - 1; i++) {
      final from = waypoints[i].position;
      final to = waypoints[i + 1].position;

      final segmentDistance = _mapService.calculateDistance(from, to);
      final bearing = _mapService.calculateBearing(from, to);
      final direction = _mapService.getCompassDirection(bearing);
      final duration = _mapService.estimateWalkingTime(segmentDistance);

      // Generate intermediate waypoints for smoother route (every ~200m)
      final intermediatePoints = _generateIntermediatePoints(from, to, 200);
      for (final point in intermediatePoints) {
        if (point != from && point != to) {
          waypoints.insert(
            waypoints.indexOf(waypoints[i + 1]),
            RoutePoint(position: point),
          );
        }
      }

      // Create step instruction
      String instruction;
      if (i == 0) {
        instruction = 'Head $direction';
        if (startName != null) {
          instruction += ' from $startName';
        }
      } else if (i == waypoints.length - 2) {
        instruction = 'Arrive at ${endName ?? "destination"}';
      } else {
        instruction = 'Continue $direction';
      }

      steps.add(RouteStep(
        instruction: instruction,
        distanceMeters: segmentDistance,
        durationSeconds: duration,
        position: from,
        direction: direction,
      ));

      totalDistance += segmentDistance;
      totalDuration += duration;
    }

    return NavigationRoute(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      start: start,
      end: end,
      waypoints: waypoints,
      steps: steps,
      totalDistanceMeters: totalDistance,
      totalDurationSeconds: totalDuration,
      createdAt: DateTime.now(),
      startName: startName,
      endName: endName,
    );
  }

  /// Generate intermediate points along a line between two points
  List<LatLng> _generateIntermediatePoints(
    LatLng start,
    LatLng end,
    double intervalMeters,
  ) {
    final points = <LatLng>[start];
    final totalDistance = _mapService.calculateDistance(start, end);

    if (totalDistance <= intervalMeters) {
      points.add(end);
      return points;
    }

    final numSegments = (totalDistance / intervalMeters).ceil();

    for (int i = 1; i < numSegments; i++) {
      final fraction = i / numSegments;
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    points.add(end);
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

  /// A* node for pathfinding
  class _AStarNode implements Comparable<_AStarNode> {
    final LatLng position;
    final double gCost; // Cost from start
    final double hCost; // Heuristic cost to end
    final _AStarNode? parent;

    _AStarNode({
      required this.position,
      required this.gCost,
      required this.hCost,
      this.parent,
    });

    double get fCost => gCost + hCost;

    @override
    int compareTo(_AStarNode other) {
      return fCost.compareTo(other.fCost);
    }
  }

  /// Heuristic function for A* (straight-line distance)
  double _heuristic(LatLng a, LatLng b) {
    return _mapService.calculateDistance(a, b);
  }

  /// A* pathfinding implementation
  /// This is a simplified version - in production, you'd use a graph with road networks
  Future<List<LatLng>> aStarPathfinding({
    required LatLng start,
    required LatLng goal,
    required List<LatLng> obstacles,
    double gridSize = 0.0001, // ~11m grid resolution
  }) async {
    final openSet = PriorityQueue<_AStarNode>();
    final closedSet = <String>{};
    final cameFrom = <String, _AStarNode>{};

    final startNode = _AStarNode(
      position: start,
      gCost: 0,
      hCost: _heuristic(start, goal),
    );

    openSet.add(startNode);

    while (openSet.isNotEmpty) {
      final current = openSet.removeFirst();
      final currentKey = _positionKey(current.position);

      if (_isGoalReached(current.position, goal)) {
        return _reconstructPath(current);
      }

      closedSet.add(currentKey);

      // Get neighbors (8 directions)
      final neighbors = _getNeighbors(current.position, gridSize);

      for (final neighborPos in neighbors) {
        final neighborKey = _positionKey(neighborPos);

        if (closedSet.contains(neighborKey)) continue;
        if (_isObstacle(neighborPos, obstacles)) continue;

        final tentativeGCost = current.gCost + _heuristic(current.position, neighborPos);

        final neighbor = _AStarNode(
          position: neighborPos,
          gCost: tentativeGCost,
          hCost: _heuristic(neighborPos, goal),
          parent: current,
        );

        if (!cameFrom.containsKey(neighborKey) ||
            tentativeGCost < cameFrom[neighborKey]!.gCost) {
          cameFrom[neighborKey] = neighbor;
          openSet.add(neighbor);
        }
      }
    }

    // No path found, return straight line
    return [start, goal];
  }

  List<LatLng> _getNeighbors(LatLng position, double gridSize) {
    return [
      LatLng(position.latitude + gridSize, position.longitude), // N
      LatLng(position.latitude + gridSize, position.longitude + gridSize), // NE
      LatLng(position.latitude, position.longitude + gridSize), // E
      LatLng(position.latitude - gridSize, position.longitude + gridSize), // SE
      LatLng(position.latitude - gridSize, position.longitude), // S
      LatLng(position.latitude - gridSize, position.longitude - gridSize), // SW
      LatLng(position.latitude, position.longitude - gridSize), // W
      LatLng(position.latitude + gridSize, position.longitude - gridSize), // NW
    ];
  }

  bool _isGoalReached(LatLng current, LatLng goal, {double threshold = 0.0001}) {
    final distance = _mapService.calculateDistance(current, goal);
    return distance < threshold * 111320; // Convert degrees to meters
  }

  bool _isObstacle(LatLng position, List<LatLng> obstacles, {double threshold = 0.0001}) {
    for (final obstacle in obstacles) {
      if ((position.latitude - obstacle.latitude).abs() < threshold &&
          (position.longitude - obstacle.longitude).abs() < threshold) {
        return true;
      }
    }
    return false;
  }

  String _positionKey(LatLng position) {
    return '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';
  }

  List<LatLng> _reconstructPath(_AStarNode node) {
    final path = <LatLng>[];
    _AStarNode? current = node;

    while (current != null) {
      path.insert(0, current.position);
      current = current.parent;
    }

    return path;
  }
}
