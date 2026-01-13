/// Model for a Ghat (bathing spot)
class Ghat {
  final String id;
  final String name;
  final String? nameHindi;
  final String description;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int walkTimeMinutes;
  final CrowdLevel crowdLevel;
  final String? bestTimeStart;
  final String? bestTimeEnd;
  final bool isGoodForBathing;
  final List<String> facilities;
  final String? imageUrl;

  Ghat({
    required this.id,
    required this.name,
    this.nameHindi,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.distanceKm = 0.0,
    this.walkTimeMinutes = 0,
    this.crowdLevel = CrowdLevel.low,
    this.bestTimeStart,
    this.bestTimeEnd,
    this.isGoodForBathing = true,
    this.facilities = const [],
    this.imageUrl,
  });

  factory Ghat.fromJson(Map<String, dynamic> json) {
    return Ghat(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHindi: json['nameHindi'] as String?,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      walkTimeMinutes: json['walkTimeMinutes'] as int? ?? 0,
      crowdLevel: CrowdLevel.values.firstWhere(
        (e) => e.name == json['crowdLevel'],
        orElse: () => CrowdLevel.low,
      ),
      bestTimeStart: json['bestTimeStart'] as String?,
      bestTimeEnd: json['bestTimeEnd'] as String?,
      isGoodForBathing: json['isGoodForBathing'] as bool? ?? true,
      facilities:
          (json['facilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameHindi': nameHindi,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'walkTimeMinutes': walkTimeMinutes,
      'crowdLevel': crowdLevel.name,
      'bestTimeStart': bestTimeStart,
      'bestTimeEnd': bestTimeEnd,
      'isGoodForBathing': isGoodForBathing,
      'facilities': facilities,
      'imageUrl': imageUrl,
    };
  }
}

enum CrowdLevel { low, medium, high }

/// Extension for crowd level display
extension CrowdLevelExtension on CrowdLevel {
  String get displayName {
    switch (this) {
      case CrowdLevel.low:
        return 'Low Crowd';
      case CrowdLevel.medium:
        return 'Medium Crowd';
      case CrowdLevel.high:
        return 'High Crowd';
    }
  }

  String get displayNameHindi {
    switch (this) {
      case CrowdLevel.low:
        return 'कम भीड़';
      case CrowdLevel.medium:
        return 'मध्यम भीड़';
      case CrowdLevel.high:
        return 'अधिक भीड़';
    }
  }
}
