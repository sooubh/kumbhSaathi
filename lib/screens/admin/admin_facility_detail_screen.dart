import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../data/models/facility.dart';
import '../../data/repositories/facility_repository.dart';
import '../../widgets/common/primary_button.dart';

/// Admin screen to view facility details and approve/reject
class AdminFacilityDetailScreen extends ConsumerStatefulWidget {
  final Facility facility;

  const AdminFacilityDetailScreen({super.key, required this.facility});

  @override
  ConsumerState<AdminFacilityDetailScreen> createState() =>
      _AdminFacilityDetailScreenState();
}

class _AdminFacilityDetailScreenState
    extends ConsumerState<AdminFacilityDetailScreen> {
  final _repository = FacilityRepository();
  bool _isProcessing = false;

  Future<void> _approveFacility() async {
    setState(() => _isProcessing = true);
    try {
      final reviewerId = FirebaseService.currentUserId ?? 'admin';
      await _repository.approveFacility(widget.facility.id, reviewerId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facility approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectFacility() async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final reviewerId = FirebaseService.currentUserId ?? 'admin';
      await _repository.rejectFacility(widget.facility.id, reviewerId, reason);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facility rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Facility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Duplicate submission, Invalid location...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: const Text('Facility Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facility Icon and Name
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIcon(),
                    size: 32,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textDarkDark
                              : AppColors.textDarkLight,
                        ),
                      ),
                      Text(
                        widget.facility.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Details
            _buildDetailRow(
              Icons.location_on,
              'Address',
              widget.facility.address ?? 'Not provided',
              isDark,
            ),
            _buildDetailRow(
              Icons.phone,
              'Phone',
              widget.facility.phone ?? 'Not provided',
              isDark,
            ),
            _buildDetailRow(
              Icons.navigation,
              'Coordinates',
              '${widget.facility.latitude.toStringAsFixed(4)}, ${widget.facility.longitude.toStringAsFixed(4)}',
              isDark,
            ),
            _buildDetailRow(
              Icons.person,
              'Submitted By',
              widget.facility.submittedBy ?? 'Unknown',
              isDark,
            ),
            _buildDetailRow(
              Icons.access_time,
              'Submitted At',
              widget.facility.submittedAt != null
                  ? _formatDate(widget.facility.submittedAt!)
                  : 'Unknown',
              isDark,
            ),

            const SizedBox(height: 48),

            // Action Buttons
            if (!_isProcessing) ...[
              PrimaryButton(
                text: 'APPROVE FACILITY',
                onPressed: _approveFacility,
                backgroundColor: AppColors.success,
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'REJECT FACILITY',
                onPressed: _rejectFacility,
                backgroundColor: AppColors.emergency,
                icon: Icons.cancel,
              ),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
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
    );
  }

  IconData _getIcon() {
    switch (widget.facility.type) {
      case FacilityType.washroom:
        return Icons.wc;
      case FacilityType.medical:
        return Icons.local_hospital;
      case FacilityType.food:
        return Icons.restaurant;
      case FacilityType.police:
        return Icons.local_police;
      case FacilityType.chargingPoint:
        return Icons.battery_charging_full;
      case FacilityType.drinkingWater:
        return Icons.water_drop;
      case FacilityType.parking:
        return Icons.local_parking;
      case FacilityType.helpDesk:
        return Icons.help;
      case FacilityType.hotel:
        return Icons.hotel;
      case FacilityType.other:
        return Icons.place;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
