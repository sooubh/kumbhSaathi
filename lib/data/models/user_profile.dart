/// Model for user profile with emergency contacts and medical info
library;
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final String? bloodGroup;
  final String? photoUrl;
  final String? phone;
  final String? email;
  final DateTime? dateOfBirth;
  final List<EmergencyContact> emergencyContacts;
  final MedicalInfo? medicalInfo;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    this.bloodGroup,
    this.photoUrl,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.emergencyContacts = const [],
    this.medicalInfo,
    this.isVerified = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bloodGroup: json['bloodGroup'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? (json['dateOfBirth'] as Timestamp).toDate()
          : null,
      emergencyContacts:
          (json['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      medicalInfo: json['medicalInfo'] != null
          ? MedicalInfo.fromJson(json['medicalInfo'] as Map<String, dynamic>)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bloodGroup': bloodGroup,
      'photoUrl': photoUrl,
      'phone': phone,
      'email': email,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'medicalInfo': medicalInfo?.toJson(),
      'isVerified': isVerified,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? bloodGroup,
    String? photoUrl,
    String? phone,
    String? email,
    DateTime? dateOfBirth,
    List<EmergencyContact>? emergencyContacts,
    MedicalInfo? medicalInfo,
    bool? isVerified,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Emergency contact model
class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      relation: json['relation'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'relation': relation, 'phone': phone};
  }
}

/// Medical information model
class MedicalInfo {
  final List<String> allergies;
  final List<String> chronicIllnesses;
  final List<String> medications;
  final String? specialNotes;

  MedicalInfo({
    this.allergies = const [],
    this.chronicIllnesses = const [],
    this.medications = const [],
    this.specialNotes,
  });

  factory MedicalInfo.fromJson(Map<String, dynamic> json) {
    return MedicalInfo(
      allergies:
          (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      chronicIllnesses:
          (json['chronicIllnesses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      medications:
          (json['medications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      specialNotes: json['specialNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergies': allergies,
      'chronicIllnesses': chronicIllnesses,
      'medications': medications,
      'specialNotes': specialNotes,
    };
  }
}
