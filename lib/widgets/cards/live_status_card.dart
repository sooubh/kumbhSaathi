import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../common/crowd_badge.dart';
import '../../data/models/ghat.dart';

/// Live crowd status card for dashboard
class LiveStatusCard extends StatelessWidget {
  final String locationName;
  final CrowdLevel crowdLevel;
  final int percentage;
  final String? suggestion;
  final bool isLive;
  final VoidCallback? onTap;

  const LiveStatusCard({
    super.key,
    required this.locationName,
    required this.crowdLevel,
    required this.percentage,
    this.suggestion,
    this.isLive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String densityText;
    switch (crowdLevel) {
      case CrowdLevel.low:
        densityText = 'Low Density';
        break;
      case CrowdLevel.medium:
        densityText = 'Medium Density';
        break;
      case CrowdLevel.high:
        densityText = 'High Density';
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sensors,
                      size: 14,
                      color: isLive
                          ? AppColors.emergency
                          : AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locationName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (isLive) _LiveIndicator(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      densityText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                    if (suggestion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        suggestion!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
                CrowdIndicator(percentage: percentage, isLive: isLive),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emergency,
            boxShadow: [
              BoxShadow(
                color: AppColors.emergency.withValues(
                  alpha: _controller.value * 0.8,
                ),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
