import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ghat.dart';

/// Crowd level indicator badge
class CrowdBadge extends StatelessWidget {
  final CrowdLevel level;
  final bool showPulse;
  final bool compact;

  const CrowdBadge({
    super.key,
    required this.level,
    this.showPulse = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String text;

    switch (level) {
      case CrowdLevel.low:
        color = AppColors.crowdLow;
        bgColor = AppColors.crowdLowBg;
        text = compact ? 'Low' : 'Low Crowd';
        break;
      case CrowdLevel.medium:
        color = AppColors.crowdMedium;
        bgColor = AppColors.crowdMediumBg;
        text = compact ? 'Medium' : 'Medium Crowd';
        break;
      case CrowdLevel.high:
        color = AppColors.crowdHigh;
        bgColor = AppColors.crowdHighBg;
        text = compact ? 'High' : 'High Crowd';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPulse)
            Container(
              width: compact ? 6 : 8,
              height: compact ? 6 : 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (showPulse) SizedBox(width: compact ? 4 : 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? 0.3 : 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated crowd level indicator with percentage
class CrowdIndicator extends StatelessWidget {
  final int percentage;
  final bool isLive;

  const CrowdIndicator({
    super.key,
    required this.percentage,
    this.isLive = true,
  });

  CrowdLevel get level {
    if (percentage >= 80) return CrowdLevel.high;
    if (percentage >= 50) return CrowdLevel.medium;
    return CrowdLevel.low;
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case CrowdLevel.low:
        color = AppColors.crowdLow;
        break;
      case CrowdLevel.medium:
        color = AppColors.crowdMedium;
        break;
      case CrowdLevel.high:
        color = AppColors.crowdHigh;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percentage >= 50 ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
