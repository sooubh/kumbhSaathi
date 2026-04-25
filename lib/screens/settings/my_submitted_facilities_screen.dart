import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/facility.dart';
import '../../data/repositories/facility_repository.dart';
import '../../screens/facilities/verify_facility_screen.dart';
import 'package:intl/intl.dart';

/// Screen for users to view their submitted facilities and their status
class MySubmittedFacilitiesScreen extends ConsumerStatefulWidget {
  const MySubmittedFacilitiesScreen({super.key});

  @override
  ConsumerState<MySubmittedFacilitiesScreen> createState() => _MySubmittedFacilitiesScreenState();
}

class _MySubmittedFacilitiesScreenState extends ConsumerState<MySubmittedFacilitiesScreen> {
  @override
  void initState() {
    super.initState();
    // Run cleanup when page loads
    FacilityRepository().cleanupExpiredFacilities();
  }

  @override
  Widget build(BuildContext context) {
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

    return StreamBuilder<List<Facility>>(
      stream: FacilityRepository().getMyFacilities(userId),
      builder: (context, snapshot) {
        final allFacilities = snapshot.data ?? [];
        final approved = allFacilities.where((f) => f.status == 'approved').toList();
        final pending = allFacilities.where((f) => f.status == 'pending').toList();

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            appBar: AppBar(
              title: const Text('My Submissions'),
              backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              bottom: TabBar(
                indicatorColor: AppColors.primaryBlue,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                tabs: [
                  Tab(text: 'Approved (${approved.length})'),
                  Tab(text: 'Pending (${pending.length})'),
                ],
              ),
            ),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? Center(child: Text('Error: ${snapshot.error}'))
                    : TabBarView(
                        children: [
                          _buildFacilityList(context, approved, true, isDark),
                          _buildFacilityList(context, pending, false, isDark),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildFacilityList(BuildContext context, List<Facility> facilities, bool isApproved, bool isDark) {
    if (facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApproved ? Icons.check_circle_outline : Icons.pending_actions,
              size: 64,
              color: AppColors.textMutedDark,
            ),
            const SizedBox(height: 16),
            Text(
              isApproved ? 'No Approved Places' : 'No Pending Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isApproved ? 'Your approved spots will appear here' : 'New submissions are being reviewed',
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
          onTap: () => _showVerificationSheet(context, facilities[index]),
        );
      },
    );
  }

  void _showVerificationSheet(BuildContext context, Facility facility) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VerificationDetailSheet(facility: facility),
    );
  }
}

class _FacilityStatusCard extends StatelessWidget {
  final Facility facility;
  final bool isDark;
  final VoidCallback onTap;

  const _FacilityStatusCard({
    required this.facility, 
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    final bool isApproved = facility.status == 'approved';
    final bool isVerified = isApproved && facility.nextVerificationDue != null && 
                            facility.nextVerificationDue!.isAfter(DateTime.now());
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isVerified ? AppColors.success.withValues(alpha: 0.3) : statusInfo.color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.1),
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
                  if (isApproved && facility.nextVerificationDue != null)
                    Text(
                      'Due: ${DateFormat('dd MMM').format(facility.nextVerificationDue!)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isVerified ? AppColors.success : AppColors.emergency,
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
                  color: AppColors.emergency.withValues(alpha: 0.1),
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

class _VerificationDetailSheet extends ConsumerStatefulWidget {
  final Facility facility;

  const _VerificationDetailSheet({required this.facility});

  @override
  ConsumerState<_VerificationDetailSheet> createState() => _VerificationDetailSheetState();
}

class _VerificationDetailSheetState extends ConsumerState<_VerificationDetailSheet> {
  bool _isVerifying = false;

  Future<void> _handleVerify() async {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyFacilityScreen(facility: widget.facility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isApproved = widget.facility.status == 'approved';
    final bool isVerified = isApproved && widget.facility.nextVerificationDue != null && 
                            widget.facility.nextVerificationDue!.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.facility.type.iconData,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.facility.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
                      ),
                    ),
                    Text(
                      widget.facility.type.displayName,
                      style: TextStyle(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoRow(
            Icons.verified_user,
            'Submission Status',
            widget.facility.status.toUpperCase(),
            isApproved ? AppColors.success : const Color(0xFFF59E0B),
            isDark,
          ),
          const SizedBox(height: 16),
          if (isApproved) ...[
            _buildInfoRow(
              Icons.verified_user,
              'Verification Status',
              isVerified ? 'VERIFIED' : 'PENDING VERIFICATION',
              isVerified ? AppColors.success : AppColors.emergency,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Last Verified',
              widget.facility.lastVerifiedAt != null 
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(widget.facility.lastVerifiedAt!)
                  : 'Never',
              isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.timer_outlined,
              'Next Verification Due',
              widget.facility.nextVerificationDue != null 
                  ? DateFormat('dd MMM yyyy').format(widget.facility.nextVerificationDue!)
                  : 'Unknown',
              isVerified ? AppColors.success : AppColors.emergency,
              isDark,
            ),
          ] else ...[
            _buildInfoRow(
              Icons.history,
              'Submission Date',
              widget.facility.submittedAt != null
                  ? DateFormat('dd MMM yyyy').format(widget.facility.submittedAt!)
                  : 'Just now',
              isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
              isDark,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waiting for admin review. Verification logic will activate once approved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          StreamBuilder<bool>(
            stream: FacilityRepository().hasPendingVerification(widget.facility.id, FirebaseService.currentUserId ?? ''),
            builder: (context, snapshot) {
              final hasPending = snapshot.data ?? false;

              if (isApproved) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (hasPending || _isVerifying) ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasPending ? AppColors.textMutedDark : AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isVerifying
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                hasPending ? 'VERIFICATION PENDING' : 'VERIFY NOW',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        hasPending 
                          ? 'Admin is reviewing your verification'
                          : 'Confirm this place is still present at this location',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkDark : AppColors.textDarkLight,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color valueColor, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                letterSpacing: 1,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension on FacilityType {
  IconData get iconData {
    switch (this) {
      case FacilityType.chargingPoint: return Icons.battery_charging_full;
      case FacilityType.washroom: return Icons.wc;
      case FacilityType.hotel: return Icons.hotel;
      case FacilityType.food: return Icons.restaurant;
      case FacilityType.medical: return Icons.local_hospital;
      case FacilityType.police: return Icons.local_police;
      case FacilityType.helpDesk: return Icons.help;
      case FacilityType.parking: return Icons.local_parking;
      case FacilityType.drinkingWater: return Icons.water_drop;
      case FacilityType.other: return Icons.place;
    }
  }
}
