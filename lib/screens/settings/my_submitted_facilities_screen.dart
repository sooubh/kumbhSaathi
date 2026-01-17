import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/facility.dart';
import '../../data/repositories/facility_repository.dart';

/// Screen for users to view their submitted facilities and their status
class MySubmittedFacilitiesScreen extends ConsumerWidget {
  const MySubmittedFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Submitted Facilities')),
        body: const Center(
          child: Text('Please log in to view your facilities'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Submitted Facilities'),
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      body: StreamBuilder<List<Facility>>(
        stream: FacilityRepository().getMyFacilities(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final facilities = snapshot.data ?? [];

          if (facilities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_business,
                    size: 64,
                    color: AppColors.textMutedDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No facilities submitted yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add places to help other pilgrims',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              return _FacilityStatusCard(
                facility: facilities[index],
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }
}

class _FacilityStatusCard extends StatelessWidget {
  final Facility facility;
  final bool isDark;

  const _FacilityStatusCard({required this.facility, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusInfo.color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.icon, size: 16, color: statusInfo.color),
                      const SizedBox(width: 6),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Facility Name
            Text(
              facility.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textDarkDark
                    : AppColors.textDarkLight,
              ),
            ),
            const SizedBox(height: 6),

            // Facility Type
            Text(
              facility.type.displayName,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 12),

            // Status Message
            Text(
              statusInfo.message,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
            ),

            // Rejection Reason (if rejected)
            if (facility.status == 'rejected' &&
                facility.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.emergency,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejection Reason:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emergency,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            facility.rejectionReason!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.emergency,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({Color color, IconData icon, String label, String message})
  _getStatusInfo() {
    switch (facility.status) {
      case 'approved':
        return (
          color: AppColors.success,
          icon: Icons.check_circle,
          label: 'Approved',
          message: 'Live on KumbhSaathi and visible to all users',
        );
      case 'rejected':
        return (
          color: AppColors.emergency,
          icon: Icons.cancel,
          label: 'Not Approved',
          message: 'Your submission was reviewed and not approved',
        );
      case 'pending':
      default:
        return (
          color: const Color(0xFFF59E0B), // Orange
          icon: Icons.access_time,
          label: 'Under Review',
          message: 'Waiting for admin approval',
        );
    }
  }
}
