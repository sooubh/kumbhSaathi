import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';

/// User profile screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Sample data
  UserProfile get _sampleProfile => UserProfile(
    id: '1',
    name: 'Rajesh Kumar',
    age: 58,
    bloodGroup: 'O+ Positive',
    isVerified: true,
    emergencyContacts: [
      EmergencyContact(
        name: 'Amit Kumar',
        relation: 'Son',
        phone: '+91 98765 43210',
      ),
      EmergencyContact(
        name: 'Suman Devi',
        relation: 'Spouse',
        phone: '+91 91234 56789',
      ),
    ],
    medicalInfo: MedicalInfo(
      allergies: ['Penicillin', 'Peanuts'],
      chronicIllnesses: ['Type 2 Diabetes', 'Hypertension'],
    ),
  );

  Future<void> _callContact(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = _sampleProfile;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
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
                    GestureDetector(
                      onTap: () {
                        // TODO: Edit profile
                      },
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
                    color: isDark
                        ? AppColors.cardDark
                        : const Color(0xFFF1F3F5),
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
                      child: Text(
                        'Emergency Contacts',
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
                                      ? AppColors.emergency.withValues(
                                          alpha: 0.1,
                                        )
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
              if (profile.medicalInfo != null)
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          profile.medicalInfo!.allergies.join(
                                            ', ',
                                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Container(
                                    height: 1,
                                    color: isDark
                                        ? AppColors.borderDark
                                        : const Color(0xFFF3F4F6),
                                  ),
                                ),
                              ],
                            ],
                            if (profile
                                .medicalInfo!
                                .chronicIllnesses
                                .isNotEmpty)
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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

              // Home Indicator
              Center(
                child: Container(
                  width: 128,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
