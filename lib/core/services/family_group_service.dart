import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import '../../data/models/family_group.dart';

/// Service for managing family tracking groups
class FamilyGroupService {
  static final FamilyGroupService _instance = FamilyGroupService._internal();
  factory FamilyGroupService() => _instance;
  FamilyGroupService._internal();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user name
  String get _currentUserName => _auth.currentUser?.displayName ?? 'User';

  /// Create a new family group
  Future<String> createGroup(String groupName) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupRef = firestore.collection('family_groups').doc();
      final inviteCode = _generateInviteCode();

      final group = FamilyGroup(
        groupId: groupRef.id,
        groupName: groupName,
        createdBy: currentUserId!,
        createdAt: DateTime.now(),
        members: {
          currentUserId!: GroupMember(
            userId: currentUserId!,
            userName: _currentUserName,
            role: 'admin',
            joinedAt: DateTime.now(),
          ),
        },
        settings: GroupSettings(),
        inviteCode: inviteCode,
        inviteExpiry: DateTime.now().add(const Duration(days: 7)),
      );

      await groupRef.set(group.toJson());
      _logger.i('✅ Group created: ${group.groupId}');
      return group.groupId;
    } catch (e) {
      _logger.e('❌ Error creating group: $e');
      rethrow;
    }
  }

  /// Join a group using invite code
  Future<void> joinGroup(String inviteCode) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Find group with this invite code
      final groupQuery = await firestore
          .collection('family_groups')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (groupQuery.docs.isEmpty) {
        throw Exception('Invalid invite code');
      }

      final groupDoc = groupQuery.docs.first;
      final group = FamilyGroup.fromJson(groupDoc.data());

      // Check if invite is expired
      if (group.inviteExpiry != null &&
          group.inviteExpiry!.isBefore(DateTime.now())) {
        throw Exception('Invite code expired');
      }

      // Check if already a member
      if (group.members.containsKey(currentUserId)) {
        throw Exception('Already a member of this group');
      }

      // Add member
      final newMember = GroupMember(
        userId: currentUserId!,
        userName: _currentUserName,
        role: 'member',
        joinedAt: DateTime.now(),
      );

      await groupDoc.reference.update({
        'members.$currentUserId': newMember.toJson(),
      });

      _logger.i('✅ Joined group: ${group.groupId}');
    } catch (e) {
      _logger.e('❌ Error joining group: $e');
      rethrow;
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupDoc = await firestore
          .collection('family_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = FamilyGroup.fromJson(groupDoc.data()!);

      // If user is the only admin, delete the group
      final admins = group.members.values
          .where((m) => m.role == 'admin')
          .toList();
      if (admins.length == 1 && admins.first.userId == currentUserId) {
        await deleteGroup(groupId);
        return;
      }

      // Remove member
      await groupDoc.reference.update({
        'members.$currentUserId': FieldValue.delete(),
      });

      _logger.i('✅ Left group: $groupId');
    } catch (e) {
      _logger.e('❌ Error leaving group: $e');
      rethrow;
    }
  }

  /// Delete a group (admin only)
  Future<void> deleteGroup(String groupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupDoc = await firestore
          .collection('family_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = FamilyGroup.fromJson(groupDoc.data()!);

      // Check if user is admin
      if (!group.isAdmin(currentUserId!)) {
        throw Exception('Only admins can delete groups');
      }

      await groupDoc.reference.delete();
      _logger.i('✅ Deleted group: $groupId');
    } catch (e) {
      _logger.e('❌ Error deleting group: $e');
      rethrow;
    }
  }

  /// Remove a member from group (admin only)
  Future<void> removeMember(String groupId, String userId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupDoc = await firestore
          .collection('family_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = FamilyGroup.fromJson(groupDoc.data()!);

      // Check if current user is admin
      if (!group.isAdmin(currentUserId!)) {
        throw Exception('Only admins can remove members');
      }

      // Cannot remove yourself
      if (userId == currentUserId) {
        throw Exception('Cannot remove yourself. Use leave group instead.');
      }

      await groupDoc.reference.update({'members.$userId': FieldValue.delete()});

      _logger.i('✅ Removed member from group');
    } catch (e) {
      _logger.e('❌ Error removing member: $e');
      rethrow;
    }
  }

  /// Stream user's groups
  Stream<List<FamilyGroup>> streamUserGroups() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return firestore
        .collection('family_groups')
        .where('members.$currentUserId', isNotEqualTo: null)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return FamilyGroup.fromJson(doc.data());
          }).toList();
        });
  }

  /// Stream group details
  Stream<FamilyGroup?> streamGroup(String groupId) {
    return firestore.collection('family_groups').doc(groupId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return FamilyGroup.fromJson(doc.data()!);
    });
  }

  /// Stream group members
  Stream<List<GroupMember>> streamGroupMembers(String groupId) {
    return firestore.collection('family_groups').doc(groupId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return <GroupMember>[];
      final group = FamilyGroup.fromJson(doc.data()!);
      return group.members.values.toList();
    });
  }

  /// Get member locations for a group
  Stream<Map<String, LatLng>> streamMemberLocations(String groupId) async* {
    await for (final groupSnapshot
        in firestore.collection('family_groups').doc(groupId).snapshots()) {
      if (!groupSnapshot.exists) {
        yield {};
        continue;
      }

      final group = FamilyGroup.fromJson(groupSnapshot.data()!);
      final memberIds = group.members.keys.toList();

      if (memberIds.isEmpty) {
        yield {};
        continue;
      }

      // Get locations for all members
      final locations = <String, LatLng>{};

      for (final memberId in memberIds) {
        final locationDoc = await firestore
            .collection('user_locations')
            .doc(memberId)
            .get();

        if (locationDoc.exists) {
          final data = locationDoc.data()!;
          locations[memberId] = LatLng(
            data['latitude'] as double,
            data['longitude'] as double,
          );
        }
      }

      yield locations;
    }
  }

  /// Generate random 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Refresh invite code for a group
  Future<void> refreshInviteCode(String groupId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupDoc = await firestore
          .collection('family_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = FamilyGroup.fromJson(groupDoc.data()!);

      if (!group.isAdmin(currentUserId!)) {
        throw Exception('Only admins can refresh invite codes');
      }

      final newCode = _generateInviteCode();
      await groupDoc.reference.update({
        'inviteCode': newCode,
        'inviteExpiry': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });

      _logger.i('✅ Refreshed invite code');
    } catch (e) {
      _logger.e('❌ Error refreshing invite code: $e');
      rethrow;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Update group settings
  Future<void> updateSettings(String groupId, GroupSettings settings) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupDoc = await firestore
          .collection('family_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = FamilyGroup.fromJson(groupDoc.data()!);

      if (!group.isAdmin(currentUserId!)) {
        throw Exception('Only admins can update settings');
      }

      await groupDoc.reference.update({'settings': settings.toJson()});

      _logger.i('✅ Updated group settings');
    } catch (e) {
      _logger.e('❌ Error updating settings: $e');
      rethrow;
    }
  }

  /// Update group settings with map (convenience method)
  Future<void> updateGroupSettings(
    String groupId,
    Map<String, dynamic> settingsMap,
  ) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final groupDoc = await firestore
          .collection('family_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = FamilyGroup.fromJson(groupDoc.data()!);

      if (!group.isAdmin(currentUserId!)) {
        throw Exception('Only admins can update settings');
      }

      // Merge with existing settings
      final currentSettings = group.settings.toJson();
      final updatedSettings = {...currentSettings, ...settingsMap};

      await groupDoc.reference.update({'settings': updatedSettings});

      _logger.i('✅ Updated group settings');
    } catch (e) {
      _logger.e('❌ Error updating settings: $e');
      rethrow;
    }
  }
}
