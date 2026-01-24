import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/family_group_service.dart';
import '../../data/models/family_group.dart';

/// Screen showing detailed view of a family group with member tracking
class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _service = FamilyGroupService();


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FamilyGroup?>(
      stream: _service.streamGroup(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Group not found')),
          );
        }

        final group = snapshot.data!;
        // Sort members: yourself first, then others
        final members = group.members.values.toList()
          ..sort((a, b) {
            if (a.userId == _service.currentUserId) return -1;
            if (b.userId == _service.currentUserId) return 1;
            return a.userName.compareTo(b.userName);
          });

        return Scaffold(
          appBar: AppBar(
            title: Text(group.groupName),
            actions: [
              IconButton( // Added key for easier finding
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsDialog(group),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Members section
              _buildSectionHeader('Members (${members.length})'),
              const SizedBox(height: 12),

              // Member location tracking
              StreamBuilder<Map<String, LatLng>>(
                stream: _service.streamMemberLocations(widget.groupId),
                builder: (context, locationSnapshot) {
                  final locations = locationSnapshot.data ?? {};

                  return Column(
                    children: members.map((member) {
                      final location = locations[member.userId];
                      final myLocation =
                          locations[_service.currentUserId ?? ''];

                      double? distance;
                      if (location != null &&
                          myLocation != null &&
                          member.userId != _service.currentUserId) {
                        distance = _service.calculateDistance(
                          myLocation,
                          location,
                        );
                      }

                      return _buildMemberCard(group, member, distance);
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Invite section
              _buildSectionHeader('Invite Members'),
              const SizedBox(height: 12),
              _buildInviteCard(group),

              const SizedBox(height: 24),

              // Leave/Delete group button
              OutlinedButton.icon(
                onPressed: () => _confirmLeaveGroup(group),
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                label: Text(
                  group.isAdmin(_service.currentUserId ?? '')
                      ? 'Delete Group'
                      : 'Leave Group',
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMemberCard(
      FamilyGroup group, GroupMember member, double? distance) {
    final isCurrentUser = member.userId == _service.currentUserId;
    final Color statusColor;
    final String statusText;

    if (isCurrentUser) {
      statusColor = Colors.blue;
      statusText = 'You';
    } else if (distance == null) {
      statusColor = Colors.grey;
      statusText = 'Location unavailable';
    } else if (distance < 100) {
      statusColor = Colors.green;
      statusText = '${distance.toInt()}m away';
    } else if (distance < 500) {
      statusColor = Colors.orange;
      statusText = '${distance.toInt()}m away';
    } else {
      statusColor = Colors.red;
      statusText = '${distance.toInt()}m away ⚠️';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (member.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (!isCurrentUser &&
                group.isAdmin(_service.currentUserId ?? '') == true)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => _confirmRemoveMember(group, member),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(FamilyGroup group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite Code',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      group.inviteCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: group.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Expires: ${_formatExpiry(group.inviteExpiry)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (group.isAdmin(_service.currentUserId ?? '')) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _refreshInviteCode(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }



  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return 'Never';

    final now = DateTime.now();
    final difference = expiry.difference(now);

    if (difference.isNegative) return 'Expired';
    if (difference.inDays > 0) return '${difference.inDays} days';
    if (difference.inHours > 0) return '${difference.inHours} hours';
    return '${difference.inMinutes} minutes';
  }


  void _showSettingsDialog(FamilyGroup group) {
    // Default values (in production, load from Firestore)
    double maxDistance = group.settings.maxDistance;
    bool enableAlerts = group.settings.enableAlerts;
    bool enableNotifications = group.settings.enableNotifications;
    bool shareLocationContinuously = group.settings.shareLocationContinuously;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Group Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Max distance slider
                const Text(
                  'Alert Distance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get notified when members are ${maxDistance.toInt()}m+ away',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Slider(
                  value: maxDistance,
                  min: 100,
                  max: 1000,
                  divisions: 9,
                  label: '${maxDistance.toInt()}m',
                  onChanged: (value) {
                    setDialogState(() => maxDistance = value);
                  },
                ),
                const SizedBox(height: 16),

                // Enable alerts switch
                SwitchListTile(
                  title: const Text('Distance Alerts'),
                  subtitle: const Text('Notify when members go too far'),
                  value: enableAlerts,
                  onChanged: (value) {
                    setDialogState(() => enableAlerts = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                // Enable notifications switch
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive mobile notifications'),
                  value: enableNotifications,
                  onChanged: (value) {
                    setDialogState(() => enableNotifications = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                // Continuous location sharing
                SwitchListTile(
                  title: const Text('Continuous Location'),
                  subtitle: const Text('Share location in real-time'),
                  value: shareLocationContinuously,
                  onChanged: (value) {
                    setDialogState(() => shareLocationContinuously = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),

                // Privacy notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location is only shared with group members',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save settings to Firestore
                try {
                  await _service.updateGroupSettings(widget.groupId, {
                    'maxDistance': maxDistance,
                    'enableAlerts': enableAlerts,
                    'enableNotifications': enableNotifications,
                    'shareLocationContinuously': shareLocationContinuously,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshInviteCode() async {
    try {
      await _service.refreshInviteCode(widget.groupId);
      // Removed _loadGroupData() as stream updates automatically

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Invite code refreshed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmRemoveMember(FamilyGroup group, GroupMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member.userName} from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member.userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(String userId) async {
    try {
      await _service.removeMember(widget.groupId, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Member removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmLeaveGroup(FamilyGroup group) {
    final isAdmin = group.isAdmin(_service.currentUserId ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdmin ? 'Delete Group' : 'Leave Group'),
        content: Text(
          isAdmin
              ? 'This will delete the group for all members. Are you sure?'
              : 'Are you sure you want to leave this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isAdmin ? 'Delete' : 'Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      await _service.leaveGroup(widget.groupId);

      if (mounted) {
        Navigator.pop(context); // Go back to group list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Left group'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
