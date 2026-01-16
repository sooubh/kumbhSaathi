/// Model for a nearby facility
library;
import 'package:cloud_firestore/cloud_firestore.dart';

class Facility {
  final String id;
  final String name;
  final String nameHindi;
  final FacilityType type;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final int walkTimeMinutes;
  final bool isOpen;
  final String? openTime;
  final String? closeTime;
  final String? phone;
  final String? address;
  final String status; // 'approved' or 'pending'
  final String? submittedBy;
  final DateTime? submittedAt;

  Facility({
    required this.id,
    required this.name,
    required this.nameHindi,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.walkTimeMinutes,
    this.isOpen = true,
    this.openTime,
    this.closeTime,
    this.phone,
    this.address,
    this.status = 'approved',
    this.submittedBy,
    this.submittedAt,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'] as String,
      name: json['name'] as String,
      nameHindi: json['nameHindi'] as String? ?? json['name'],
      type: FacilityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FacilityType.other,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      walkTimeMinutes: json['walkTimeMinutes'] as int? ?? 0,
      isOpen: json['isOpen'] as bool? ?? true,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'approved',
      submittedBy: json['submittedBy'] as String?,
      submittedAt: json['submittedAt'] != null
          ? (json['submittedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameHindi': nameHindi,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'distanceMeters': distanceMeters,
      'walkTimeMinutes': walkTimeMinutes,
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'phone': phone,
      'address': address,
      'status': status,
      'submittedBy': submittedBy,
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : null,
    };
  }
}

enum FacilityType {
  chargingPoint,
  washroom,
  hotel,
  food,
  medical,
  police,
  helpDesk,
  parking,
  drinkingWater,
  other,
}

/// Extension for facility type display
extension FacilityTypeExtension on FacilityType {
  String get displayName {
    switch (this) {
      case FacilityType.chargingPoint:
        return 'Charging Point';
      case FacilityType.washroom:
        return 'Washroom';
      case FacilityType.hotel:
        return 'Hotel';
      case FacilityType.food:
        return 'Food & Prasad';
      case FacilityType.medical:
        return 'Medical Help';
      case FacilityType.police:
        return 'Police Station';
      case FacilityType.helpDesk:
        return 'Help Desk';
      case FacilityType.parking:
        return 'Parking';
      case FacilityType.drinkingWater:
        return 'Drinking Water';
      case FacilityType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case FacilityType.chargingPoint:
        return 'battery_charging_full';
      case FacilityType.washroom:
        return 'wc';
      case FacilityType.hotel:
        return 'hotel';
      case FacilityType.food:
        return 'restaurant';
      case FacilityType.medical:
        return 'local_hospital';
      case FacilityType.police:
        return 'local_police';
      case FacilityType.helpDesk:
        return 'help';
      case FacilityType.parking:
        return 'local_parking';
      case FacilityType.drinkingWater:
        return 'water_drop';
      case FacilityType.other:
        return 'place';
    }
  }
}
