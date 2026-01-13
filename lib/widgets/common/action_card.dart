import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Quick action card for home screen grid
class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final bool isPrimary;
  final bool isEmergency;
  final double iconSize;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.isPrimary = false,
    this.isEmergency = false,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine colors based on variant
    Color bgColor;
    Color iconBgColor;
    Color iconFgColor;
    Color borderColor;

    if (isEmergency) {
      bgColor = AppColors.emergency.withValues(alpha: 0.1);
      iconBgColor = AppColors.emergency;
      iconFgColor = Colors.white;
      borderColor = AppColors.emergency.withValues(alpha: 0.2);
    } else if (isPrimary) {
      bgColor = AppColors.primaryOrange.withValues(alpha: 0.1);
      iconBgColor = AppColors.primaryOrange;
      iconFgColor = Colors.white;
      borderColor = AppColors.primaryOrange.withValues(alpha: 0.2);
    } else {
      bgColor = backgroundColor ?? (isDark ? AppColors.cardDark : Colors.white);
      iconBgColor =
          iconBackgroundColor ??
          (isDark ? AppColors.cardSecondaryDark : const Color(0xFFF3F4F6));
      iconFgColor =
          iconColor ??
          (isDark ? AppColors.textMutedDark : const Color(0xFF6B7280));
      borderColor = isDark ? AppColors.borderDark : const Color(0xFFE5E7EB);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isPrimary || isEmergency
              ? [
                  BoxShadow(
                    color:
                        (isEmergency
                                ? AppColors.emergency
                                : AppColors.primaryOrange)
                            .withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isPrimary || isEmergency ? 80 : 64,
              height: isPrimary || isEmergency ? 80 : 64,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                boxShadow: isPrimary || isEmergency
                    ? [
                        BoxShadow(
                          color: iconBgColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: isPrimary || isEmergency ? iconSize + 10 : iconSize,
                color: iconFgColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isPrimary || isEmergency ? 18 : 16,
                fontWeight: isPrimary || isEmergency
                    ? FontWeight.w800
                    : FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkDark
                    : AppColors.textDarkLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
