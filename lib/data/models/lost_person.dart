/// Model for a lost person report
class LostPerson {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String? photoUrl;
  final String lastSeenLocation;
  final double? lastSeenLat;
  final double? lastSeenLng;
  final String? description;
  final String? voiceDescriptionUrl;
  final String guardianName;
  final String guardianPhone;
  final String? guardianAddress;
  final DateTime reportedAt;
  final LostPersonStatus status;

  LostPerson({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.photoUrl,
    required this.lastSeenLocation,
    this.lastSeenLat,
    this.lastSeenLng,
    this.description,
    this.voiceDescriptionUrl,
    required this.guardianName,
    required this.guardianPhone,
    this.guardianAddress,
    required this.reportedAt,
    this.status = LostPersonStatus.missing,
  });

  factory LostPerson.fromJson(Map<String, dynamic> json) {
    return LostPerson(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      photoUrl: json['photoUrl'] as String?,
      lastSeenLocation: json['lastSeenLocation'] as String,
      lastSeenLat: json['lastSeenLat'] as double?,
      lastSeenLng: json['lastSeenLng'] as double?,
      description: json['description'] as String?,
      voiceDescriptionUrl: json['voiceDescriptionUrl'] as String?,
      guardianName: json['guardianName'] as String,
      guardianPhone: json['guardianPhone'] as String,
      guardianAddress: json['guardianAddress'] as String?,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      status: LostPersonStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LostPersonStatus.missing,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'photoUrl': photoUrl,
      'lastSeenLocation': lastSeenLocation,
      'lastSeenLat': lastSeenLat,
      'lastSeenLng': lastSeenLng,
      'description': description,
      'voiceDescriptionUrl': voiceDescriptionUrl,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'guardianAddress': guardianAddress,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status.name,
    };
  }

  LostPerson copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? photoUrl,
    String? lastSeenLocation,
    double? lastSeenLat,
    double? lastSeenLng,
    String? description,
    String? voiceDescriptionUrl,
    String? guardianName,
    String? guardianPhone,
    String? guardianAddress,
    DateTime? reportedAt,
    LostPersonStatus? status,
  }) {
    return LostPerson(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      lastSeenLat: lastSeenLat ?? this.lastSeenLat,
      lastSeenLng: lastSeenLng ?? this.lastSeenLng,
      description: description ?? this.description,
      voiceDescriptionUrl: voiceDescriptionUrl ?? this.voiceDescriptionUrl,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianAddress: guardianAddress ?? this.guardianAddress,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
    );
  }
}

enum LostPersonStatus { missing, found, searching }
