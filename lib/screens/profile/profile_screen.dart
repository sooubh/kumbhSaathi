import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/models/user_activity.dart';
import 'package:intl/intl.dart';

/// User profile provider
final userProfileStreamProvider = StreamProvider<UserProfile?>((ref) {
  final userId = FirebaseService.currentUserId;
  if (userId == null) return Stream.value(null);
  return UserRepository().getUserProfileStream(userId);
});

/// User profile screen
class ProfileScreen extends ConsumerStatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Sample data for when user is not logged in
  UserProfile get _sampleProfile => UserProfile(
    id: '1',
    name: 'Pilgrim User',
    age: 45,
    bloodGroup: 'O+ Positive',
    isVerified: false,
    emergencyContacts: [
      EmergencyContact(
        name: 'Family Member',
        relation: 'Relative',
        phone: '+91 98765 43210',
      ),
    ],
    medicalInfo: MedicalInfo(allergies: [], chronicIllnesses: []),
  );

  Future<void> _callContact(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch relevant providers
    // final authState = ref.watch(authProvider); // Assuming authProvider exists and is imported
    // final userActivitiesAsync = ref.watch(userActivitiesProvider); // Assuming userActivitiesProvider exists and is imported
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SafeArea(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  _buildProfileContent(context, ref, isDark, _sampleProfile),
              data: (profile) => _buildProfileContent(
                context,
                ref,
                isDark,
                profile ?? _sampleProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    UserProfile profile,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (widget.showBackButton)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: isDark
                                ? AppColors.textDarkDark
                                : AppColors.textDarkLight,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      'User Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                  ],
                ),
                if (FirebaseService.isLoggedIn)
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(context, ref, profile),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: 20,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Profile Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardSecondaryDark
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF0056B3,
                            ).withValues(alpha: 0.2),
                            width: 4,
                          ),
                        ),
                        child: ClipOval(
                          child: profile.photoUrl != null
                              ? Image.network(
                                  profile.photoUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.person,
                                  size: 64,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : const Color(0xFF9CA3AF),
                                ),
                        ),
                      ),
                      if (profile.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0056B3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.cardDark
                                    : const Color(0xFFF1F3F5),
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Name
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                  if (!FirebaseService.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () async {
                          await FirebaseService.signInAnonymously();
                          ref.invalidate(userProfileStreamProvider);
                        },
                        child: const Text('Sign in to save profile'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'AGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.age}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDarkDark
                                  : AppColors.textDarkLight,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFD1D5DB),
                      ),
                      Column(
                        children: [
                          Text(
                            'BLOOD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.bloodGroup ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emergency,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Emergency Contacts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDarkDark
                              : AppColors.textDarkLight,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showAddContactDialog(context, ref, profile),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (profile.emergencyContacts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'No emergency contacts added',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  )
                else
                  ...profile.emergencyContacts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final contact = entry.value;
                    final isPrimary = index == 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isPrimary
                                    ? AppColors.emergency.withValues(alpha: 0.1)
                                    : (isDark
                                          ? AppColors.cardSecondaryDark
                                          : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.family_restroom,
                                color: isPrimary
                                    ? AppColors.emergency
                                    : (isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${contact.name} (${contact.relation})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textDarkDark
                                          : AppColors.textDarkLight,
                                    ),
                                  ),
                                  Text(
                                    contact.phone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _callContact(contact.phone),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isPrimary
                                      ? AppColors.emergency
                                      : const Color(0xFF4B5563),
                                  shape: BoxShape.circle,
                                  boxShadow: isPrimary
                                      ? [
                                          BoxShadow(
                                            color: AppColors.emergency
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Medical Conditions
          if (profile.medicalInfo != null &&
              (profile.medicalInfo!.allergies.isNotEmpty ||
                  profile.medicalInfo!.chronicIllnesses.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Medical Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (profile.medicalInfo!.allergies.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ALLERGIES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.medicalInfo!.allergies.join(', '),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textDarkDark
                                            : AppColors.textDarkLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (profile
                              .medicalInfo!
                              .chronicIllnesses
                              .isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Container(
                                height: 1,
                                color: isDark
                                    ? AppColors.borderDark
                                    : const Color(0xFFF3F4F6),
                              ),
                            ),
                          ],
                        ],
                        if (profile.medicalInfo!.chronicIllnesses.isNotEmpty)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.history_edu,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CHRONIC ILLNESS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.medicalInfo!.chronicIllnesses
                                          .join(', '),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.textDarkDark
                                            : AppColors.textDarkLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          // Recent Activity Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                ),
                const SizedBox(height: 12),
                _RecentActivityList(userId: profile.id, isDark: isDark),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Home Indicator
          Center(
            child: Container(
              width: 128,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age.toString());
    final bloodController = TextEditingController(
      text: profile.bloodGroup ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bloodController,
                decoration: const InputDecoration(labelText: 'Blood Group'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedProfile = profile.copyWith(
                name: nameController.text.trim(),
                age: int.tryParse(ageController.text) ?? profile.age,
                bloodGroup: bloodController.text.trim(),
              );
              await UserRepository().saveProfile(updatedProfile);
              ref.invalidate(userProfileStreamProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(labelText: 'Relation'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final contact = EmergencyContact(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                relation: relationController.text.trim(),
              );
              await UserRepository().addEmergencyContact(profile.id, contact);
              ref.invalidate(userProfileStreamProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final String userId;
  final bool isDark;

  const _RecentActivityList({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserActivity>>(
      stream: ActivityRepository().getUserActivities(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading activity');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data!;
        if (activities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                const SizedBox(width: 12),
                const Text('No recent activity'),
              ],
            ),
          );
        }

        return Column(
          children: activities
              .map((activity) => _buildActivityItem(activity))
              .toList(),
        );
      },
    );
  }

  Widget _buildActivityItem(UserActivity activity) {
    IconData icon;
    Color color;
    String title;

    switch (activity.type) {
      case ActivityType.image:
        icon = Icons.image;
        color = Colors.blue;
        title = 'Uploaded Photo';
        break;
      case ActivityType.voice:
        icon = Icons.mic;
        color = Colors.orange;
        title = 'Voice Note';
        break;
      case ActivityType.emergency:
      case ActivityType.sos:
        icon = Icons.warning;
        color = Colors.red;
        title = 'Emergency Alert';
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
        title = 'Activity';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(activity.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
