import 'package:flutter/material.dart';
import '../../data/models/map_marker_model.dart';
import '../../core/theme/app_colors.dart';

/// Custom marker widget for different marker types
class CustomMarkerWidget extends StatelessWidget {
  final CustomMapMarker marker;
  final VoidCallback? onTap;

  const CustomMarkerWidget({
    super.key,
    required this.marker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing animation for certain markers
          if (marker.isPulsing) _buildPulsingCircle(),

          // Main marker
          _buildMarkerIcon(),

          // Label for ghats
          if (marker.type == MapMarkerType.ghat) _buildLabel(),
        ],
      ),
    );
  }

  Widget _buildMarkerIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: marker.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: marker.color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        marker.icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildPulsingCircle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: marker.color.withValues(alpha: 0.3),
            ),
          ),
        );
      },
      onEnd: () {
        // Rebuild to restart animation
        if (onTap != null) {
          // This is a hack to force rebuild
        }
      },
    );
  }

  Widget _buildLabel() {
    return Positioned(
      top: 50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: marker.color,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          marker.title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: marker.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Animated pulsing marker widget
class PulsingMarker extends StatefulWidget {
  final CustomMapMarker marker;
  final VoidCallback? onTap;

  const PulsingMarker({
    super.key,
    required this.marker,
    this.onTap,
  });

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing effect
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.marker.color.withValues(alpha: 0.3),
                  ),
                ),
              );
            },
          ),

          // Main marker
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.marker.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.marker.color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              widget.marker.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// User location marker with accuracy ring
class UserLocationMarker extends StatelessWidget {
  final double accuracy; // in meters
  final Color color;

  const UserLocationMarker({
    super.key,
    this.accuracy = 10,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Accuracy ring
        Container(
          width: _calculateAccuracySize(accuracy),
          height: _calculateAccuracySize(accuracy),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),

        // User dot
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateAccuracySize(double accuracy) {
    // Convert meters to visual size (simplified)
    // This should be scaled based on zoom level in production
    return (accuracy * 0.5).clamp(30, 100);
  }
}
