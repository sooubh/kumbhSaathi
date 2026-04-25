import 'package:cloud_firestore/cloud_firestore.dart';

/// Family group model for tracking family members together
class FamilyGroup {
  final String groupId;
  final String groupName;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, GroupMember> members;
  final GroupSettings settings;
  final String inviteCode;
  final DateTime? inviteExpiry;

  FamilyGroup({
    required this.groupId,
    required this.groupName,
    required this.createdBy,
    required this.createdAt,
    required this.members,
    required this.settings,
    required this.inviteCode,
    this.inviteExpiry,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    final membersMap = <String, GroupMember>{};
    if (json['members'] != null) {
      (json['members'] as Map<String, dynamic>).forEach((key, value) {
        membersMap[key] = GroupMember.fromJson(value as Map<String, dynamic>);
      });
    }

    return FamilyGroup(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      members: membersMap,
      settings: GroupSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      inviteCode: json['inviteCode'] as String,
      inviteExpiry: json['inviteExpiry'] != null
          ? (json['inviteExpiry'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final membersJson = <String, dynamic>{};
    members.forEach((key, value) {
      membersJson[key] = value.toJson();
    });

    return {
      'groupId': groupId,
      'groupName': groupName,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': membersJson,
      'settings': settings.toJson(),
      'inviteCode': inviteCode,
      'inviteExpiry': inviteExpiry != null
          ? Timestamp.fromDate(inviteExpiry!)
          : null,
    };
  }

  /// Check if user is admin of this group
  bool isAdmin(String userId) {
    final member = members[userId];
    return member?.role == 'admin';
  }

  /// Get member count
  int get memberCount => members.length;

  /// Get active members
  List<GroupMember> get activeMembers {
    return members.values.where((m) => m.isActive).toList();
  }

  /// Copy with method for updates
  FamilyGroup copyWith({
    String? groupName,
    Map<String, GroupMember>? members,
    GroupSettings? settings,
    String? inviteCode,
    DateTime? inviteExpiry,
  }) {
    return FamilyGroup(
      groupId: groupId,
      groupName: groupName ?? this.groupName,
      createdBy: createdBy,
      createdAt: createdAt,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiry: inviteExpiry ?? this.inviteExpiry,
    );
  }
}

/// Group member model
class GroupMember {
  final String userId;
  final String userName;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final bool isActive;

  GroupMember({
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      role: json['role'] as String,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }

  /// Check if member is admin
  bool get isAdmin => role == 'admin';

  /// Copy with method
  GroupMember copyWith({String? userName, String? role, bool? isActive}) {
    return GroupMember(
      userId: userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      joinedAt: joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Group settings model
class GroupSettings {
  final double maxDistance; // in meters
  final bool enableAlerts;
  final bool enableNotifications;
  final bool shareLocationContinuously;

  GroupSettings({
    this.maxDistance = 500.0,
    this.enableAlerts = true,
    this.enableNotifications = true,
    this.shareLocationContinuously = true,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) {
    return GroupSettings(
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 500.0,
      enableAlerts: json['enableAlerts'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      shareLocationContinuously: json['shareLocationContinuously'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDistance': maxDistance,
      'enableAlerts': enableAlerts,
      'enableNotifications': enableNotifications,
      'shareLocationContinuously': shareLocationContinuously,
    };
  }

  /// Copy with method
  GroupSettings copyWith({
    double? maxDistance,
    bool? enableAlerts,
    bool? enableNotifications,
    bool? shareLocationContinuously,
  }) {
    return GroupSettings(
      maxDistance: maxDistance ?? this.maxDistance,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      shareLocationContinuously:
          shareLocationContinuously ?? this.shareLocationContinuously,
    );
  }
}
