import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/realtime_crowd_service.dart';
import '../../core/theme/app_colors.dart';

/// Realtime Kumbh Mela Dashboard Widget
/// Shows live crowd statistics and updates
class RealtimeKumbhDashboard extends ConsumerWidget {
  const RealtimeKumbhDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with LIVE indicator
          Row(
            children: [
              Text(
                '🕉️ Kumbh Mela Live',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
              ),
              const SizedBox(width: 12),
              _buildLiveIndicator(),
            ],
          ),
          const SizedBox(height: 20),

          // Realtime crowd stats
          StreamBuilder<Map<String, dynamic>>(
            stream: RealtimeCrowdService().streamCrowdStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const Text('No data available');
              }

              final stats = snapshot.data!;
              final lowCrowd = stats['lowCrowd'] as int? ?? 0;
              final mediumCrowd = stats['mediumCrowd'] as int? ?? 0;
              final highCrowd = stats['highCrowd'] as int? ?? 0;
              final totalGhats = stats['totalGhats'] as int? ?? 0;

              return Column(
                children: [
                  // Total ghats
                  _buildStatCard(
                    isDark,
                    'Total Ghats',
                    totalGhats.toString(),
                    Icons.water,
                    AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 12),

                  // Crowd levels
                  Row(
                    children: [
                      Expanded(
                        child: _buildCrowdCard(
                          isDark,
                          'Low Crowd',
                          lowCrowd.toString(),
                          AppColors.success,
                          '🟢',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCrowdCard(
                          isDark,
                          'Medium',
                          mediumCrowd.toString(),
                          Colors.orange,
                          '🟠',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCrowdCard(
                          isDark,
                          'High Crowd',
                          highCrowd.toString(),
                          AppColors.emergency,
                          '🔴',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Recommendation
                  _buildRecommendation(isDark, lowCrowd, highCrowd),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.emergency.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.emergency.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.emergency,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdCard(
    bool isDark,
    String label,
    String value,
    Color color,
    String emoji,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(bool isDark, int lowCrowd, int highCrowd) {
    String message;
    IconData icon;
    Color color;

    if (lowCrowd > 0) {
      message = '$lowCrowd ghat${lowCrowd > 1 ? 's are' : ' is'} less crowded. Visit now!';
      icon = Icons.check_circle;
      color = AppColors.success;
    } else if (highCrowd > 3) {
      message = 'All major ghats are crowded. Consider visiting later.';
      icon = Icons.warning;
      color = AppColors.emergency;
    } else {
      message = 'Moderate crowd levels across ghats.';
      icon = Icons.info;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot indicator for LIVE status
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
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
        return Opacity(
          opacity: 0.3 + (0.7 * _controller.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.emergency,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
