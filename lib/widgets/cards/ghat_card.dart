import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ghat.dart';
import '../common/crowd_badge.dart';
import '../common/primary_button.dart';

/// Ghat information card for navigation screen
class GhatCard extends StatelessWidget {
  final Ghat ghat;
  final VoidCallback? onNavigate;
  final VoidCallback? onTap;
  final bool isSelected;

  const GhatCard({
    super.key,
    required this.ghat,
    this.onNavigate,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ghat.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDarkDark
                              : AppColors.textDarkLight,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                            '${ghat.walkTimeMinutes} min • ${ghat.distanceKm.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
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
                CrowdBadge(level: ghat.crowdLevel, compact: true),
              ],
            ),
            const SizedBox(height: 12),
            if (ghat.bestTimeStart != null && ghat.bestTimeEnd != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardSecondaryDark
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BEST TIME',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        Text(
                          '${ghat.bestTimeStart} - ${ghat.bestTimeEnd}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textDarkDark
                                : AppColors.textDarkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else if (ghat.isGoodForBathing)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardSecondaryDark
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 18, color: AppColors.success),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        Text(
                          'Good for Bathing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textDarkDark
                                : AppColors.textDarkLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'Start Navigation',
              onPressed: onNavigate,
              height: 44,
              borderRadius: 12,
              backgroundColor: ghat.crowdLevel == CrowdLevel.high
                  ? (isDark
                        ? AppColors.cardSecondaryDark
                        : const Color(0xFFF3F4F6))
                  : AppColors.primaryBlue,
              textColor: ghat.crowdLevel == CrowdLevel.high
                  ? (isDark ? AppColors.textDarkDark : AppColors.textDarkLight)
                  : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
