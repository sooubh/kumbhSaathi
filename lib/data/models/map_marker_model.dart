import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Types of markers that can be displayed on the map
enum MapMarkerType {
  ghat,
  facility,
  emergency,
  user,
  poi, // Point of Interest
}

/// Custom map marker with type, position, and metadata
class CustomMapMarker {
  final String id;
  final MapMarkerType type;
  final LatLng position;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Map<String, dynamic>? metadata;
  final bool isPulsing;

  CustomMapMarker({
    required this.id,
    required this.type,
    required this.position,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.metadata,
    this.isPulsing = false,
  });

  /// Create a ghat marker
  factory CustomMapMarker.ghat({
    required String id,
    required LatLng position,
    required String name,
    required Color crowdColor,
    Map<String, dynamic>? metadata,
  }) {
    return CustomMapMarker(
      id: id,
      type: MapMarkerType.ghat,
      position: position,
      title: name,
      icon: Icons.water,
      color: crowdColor,
      metadata: metadata,
    );
  }

  /// Create a facility marker
  factory CustomMapMarker.facility({
    required String id,
    required LatLng position,
    required String name,
    required IconData icon,
    Map<String, dynamic>? metadata,
  }) {
    return CustomMapMarker(
      id: id,
      type: MapMarkerType.facility,
      position: position,
      title: name,
      icon: icon,
      color: Colors.blue,
      metadata: metadata,
    );
  }

  /// Create an emergency marker
  factory CustomMapMarker.emergency({
    required String id,
    required LatLng position,
    required String name,
    Map<String, dynamic>? metadata,
  }) {
    return CustomMapMarker(
      id: id,
      type: MapMarkerType.emergency,
      position: position,
      title: name,
      icon: Icons.emergency,
      color: Colors.red,
      metadata: metadata,
      isPulsing: true,
    );
  }

  /// Create a user location marker
  factory CustomMapMarker.userLocation({
    required String userId,
    required LatLng position,
    required String userName,
    Map<String, dynamic>? metadata,
  }) {
    return CustomMapMarker(
      id: userId,
      type: MapMarkerType.user,
      position: position,
      title: userName,
      icon: Icons.person_pin_circle,
      color: Colors.blue,
      metadata: metadata,
      isPulsing: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'title': title,
      'subtitle': subtitle,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'metadata': metadata,
      'isPulsing': isPulsing,
    };
  }

  factory CustomMapMarker.fromJson(Map<String, dynamic> json) {
    return CustomMapMarker(
      id: json['id'] as String,
      type: MapMarkerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MapMarkerType.poi,
      ),
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(json['colorValue'] as int),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPulsing: json['isPulsing'] as bool? ?? false,
    );
  }

  CustomMapMarker copyWith({
    String? id,
    MapMarkerType? type,
    LatLng? position,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? color,
    Map<String, dynamic>? metadata,
    bool? isPulsing,
  }) {
    return CustomMapMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      isPulsing: isPulsing ?? this.isPulsing,
    );
  }
}
