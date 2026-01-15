import 'package:latlong2/latlong.dart';

/// Represents a single point in a route
class RoutePoint {
  final LatLng position;
  final double? elevation;
  final String? name;

  RoutePoint({
    required this.position,
    this.elevation,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'elevation': elevation,
      'name': name,
    };
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      elevation: json['elevation'] as double?,
      name: json['name'] as String?,
    );
  }
}

/// Represents a single step/instruction in a route
class RouteStep {
  final String instruction;
  final double distanceMeters;
  final int durationSeconds;
  final LatLng position;
  final String direction; // e.g., "north", "northeast", "turn left"

  RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.position,
    required this.direction,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toInt()}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'direction': direction,
    };
  }

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: json['instruction'] as String,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: json['durationSeconds'] as int,
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      direction: json['direction'] as String,
    );
  }
}

/// Complete navigation route
class NavigationRoute {
  final String id;
  final LatLng start;
  final LatLng end;
  final List<RoutePoint> waypoints;
  final List<RouteStep> steps;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final DateTime createdAt;
  final String? startName;
  final String? endName;

  NavigationRoute({
    required this.id,
    required this.start,
    required this.end,
    required this.waypoints,
    required this.steps,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.createdAt,
    this.startName,
    this.endName,
  });

  String get formattedTotalDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.toInt()}m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(2)}km';
    }
  }

  String get formattedTotalDuration {
    final minutes = (totalDurationSeconds / 60).round();
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}min';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startLatitude': start.latitude,
      'startLongitude': start.longitude,
      'endLatitude': end.latitude,
      'endLongitude': end.longitude,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'totalDistanceMeters': totalDistanceMeters,
      'totalDurationSeconds': totalDurationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'startName': startName,
      'endName': endName,
    };
  }

  factory NavigationRoute.fromJson(Map<String, dynamic> json) {
    return NavigationRoute(
      id: json['id'] as String,
      start: LatLng(
        json['startLatitude'] as double,
        json['startLongitude'] as double,
      ),
      end: LatLng(
        json['endLatitude'] as double,
        json['endLongitude'] as double,
      ),
      waypoints: (json['waypoints'] as List)
          .map((w) => RoutePoint.fromJson(w as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List)
          .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
      totalDurationSeconds: json['totalDurationSeconds'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startName: json['startName'] as String?,
      endName: json['endName'] as String?,
    );
  }
}
