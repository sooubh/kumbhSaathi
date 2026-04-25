import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/facility.dart';
import '../../screens/facilities/facility_detail_sheet.dart';

/// Compact horizontal card for displaying facility information
class FacilityCard extends StatelessWidget {
  final Facility facility;
  final VoidCallback? onTap;

  const FacilityCard({super.key, required this.facility, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap ?? () => FacilityDetailSheet.show(context, facility),
      child: Container(
        // width: 200, // Removed for responsive grid
        // margin: const EdgeInsets.only(right: 12), // Removed for responsive grid
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Status Row
              Row(
                children: [
                  Container(
                    width: 36, // Slightly smaller icon bg
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getIconColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFacilityIcon(),
                      color: _getIconColor(),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (facility.isOpen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Facility Name
              Expanded(
                // Use Expanded to take available space instead of fixed Text height risking overflow
                child: Text(
                  facility.name,
                  style: TextStyle(
                    fontSize: 13, // Slightly smaller font
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),

              // Distance Info
              Row(
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 14,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${facility.distanceMeters}m • ${facility.walkTimeMinutes} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFacilityIcon() {
    switch (facility.type) {
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

  Color _getIconColor() {
    switch (facility.type) {
      case FacilityType.washroom:
        return const Color(0xFF3B82F6); // Blue
      case FacilityType.medical:
        return const Color(0xFFEF4444); // Red
      case FacilityType.food:
        return const Color(0xFFF59E0B); // Amber
      case FacilityType.police:
        return const Color(0xFF6366F1); // Indigo
      case FacilityType.chargingPoint:
        return const Color(0xFF10B981); // Green
      case FacilityType.drinkingWater:
        return const Color(0xFF06B6D4); // Cyan
      case FacilityType.parking:
        return const Color(0xFF8B5CF6); // Purple
      case FacilityType.helpDesk:
        return AppColors.primaryOrange;
      case FacilityType.hotel:
        return const Color(0xFFEC4899); // Pink
      case FacilityType.other:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
