import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/voice_session_provider.dart';

class VoiceAssistantSheet extends ConsumerStatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  ConsumerState<VoiceAssistantSheet> createState() =>
      _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends ConsumerState<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // ── KEY FIX ──────────────────────────────────────────────────────────────
  // Cache the notifier during initState while ref is still valid.
  // dispose() MUST NOT call ref.read() — the Riverpod container may have
  // already torn down the ref by the time dispose() runs, which causes:
  //   "Bad state: Cannot use ref after the widget was disposed"
  // Holding a direct reference to the notifier sidesteps this entirely.
  // ─────────────────────────────────────────────────────────────────────────
  late final VoiceSessionNotifier _notifier;

  @override
  void initState() {
    super.initState();

    // Cache notifier NOW — ref is fully valid in initState
    _notifier = ref.read(voiceSessionProvider.notifier);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Start the voice session after the first frame so the sheet is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifier.connect();
    });
  }

  @override
  void dispose() {
    // Safe: uses the cached notifier, not ref
    _notifier.disconnect();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // Animated status indicator
            _StatusOrb(
              controller: _pulseController,
              voiceState: voiceState,
            ),

            const SizedBox(height: 28),

            // Status label
            Text(
              _statusHeading(voiceState),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            // Transcript / status sub-text
            if (voiceState.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(voiceState.text),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    voiceState.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],

            // Error + retry
            if (voiceState.status == VoiceState.error ||
                voiceState.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorCard(
                message: voiceState.errorMessage ?? 'Unknown error',
                onRetry: () => _notifier.connect(),
              ),
            ],

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Close / dismiss
                _CircleAction(
                  icon: Icons.close,
                  bg: Colors.grey.shade200,
                  fg: Colors.black87,
                  onTap: () {
                    _notifier.disconnect();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 24),

                // Stop session
                FloatingActionButton(
                  heroTag: 'voice_stop_btn',
                  backgroundColor: AppColors.primaryBlue,
                  onPressed: () {
                    _notifier.disconnect();
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.stop_rounded, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusHeading(VoiceSessionState s) {
    switch (s.status) {
      case VoiceState.initial:
        return 'Ready';
      case VoiceState.connecting:
        return 'Connecting to Gemini Live…';
      case VoiceState.listening:
        return 'Listening…';
      case VoiceState.speaking:
        return 'Gemini is speaking…';
      case VoiceState.error:
        return 'Connection Error';
    }
  }
}

// ── Sub-widgets (kept small and focused) ─────────────────────────────────────

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({
    required this.controller,
    required this.voiceState,
  });

  final AnimationController controller;
  final VoiceSessionState voiceState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value; // 0 → 1 oscillating
          double scale = 1.0;
          Color color;

          switch (voiceState.status) {
            case VoiceState.connecting:
              color = Colors.orange;
              scale = 1.0 + t * 0.08;
              break;
            case VoiceState.listening:
              color = AppColors.primaryBlue;
              scale = 1.0 + t * 0.18;
              break;
            case VoiceState.speaking:
              color = AppColors.success;
              scale = 1.0 + t * 0.12;
              break;
            case VoiceState.error:
              color = AppColors.emergency;
              break;
            default:
              color = AppColors.primaryBlue;
          }

          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Container(
                width: 80 * scale,
                height: 80 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _iconFor(voiceState.status),
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(VoiceState s) {
    switch (s) {
      case VoiceState.listening:
        return Icons.mic_rounded;
      case VoiceState.speaking:
        return Icons.volume_up_rounded;
      case VoiceState.connecting:
        return Icons.wifi_calling_3_rounded;
      case VoiceState.error:
        return Icons.mic_off_rounded;
      default:
        return Icons.mic_rounded;
    }
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          style: TextStyle(color: AppColors.emergency, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry Connection'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emergency,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg),
      ),
    );
  }
}
