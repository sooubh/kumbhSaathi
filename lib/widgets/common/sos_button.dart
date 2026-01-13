import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Large pulsing SOS emergency button
class SOSButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final int holdDurationSeconds;
  final double size;

  const SOSButton({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.holdDurationSeconds = 3,
    this.size = 200,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
        return SizedBox(
          width: widget.size + 40,
          height: widget.size + 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width: widget.size + 40,
                height: widget.size + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergency.withValues(
                    alpha: _pulseAnimation.value * 0.3,
                  ),
                ),
              ),
              // Middle ring
              Container(
                width: widget.size + 20,
                height: widget.size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergency.withValues(
                    alpha: _pulseAnimation.value * 0.5,
                  ),
                ),
              ),
              // Main button
              GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed?.call();
                },
                onTapCancel: () => setState(() => _isPressed = false),
                onLongPress: widget.onLongPress,
                child: AnimatedScale(
                  scale: _isPressed ? 0.95 : _scaleAnimation.value,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergency,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergency.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sos, color: Colors.white, size: 64),
                        const SizedBox(height: 4),
                        const Text(
                          'HELP ME',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Hold for ${widget.holdDurationSeconds}s',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
