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
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Auto-start listening when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceSessionProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(voiceSessionProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // Status Visual
            SizedBox(
              height: 120,
              width: 120,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;
                  Color color = AppColors.primaryBlue;

                  switch (voiceState.status) {
                    case VoiceState.listening:
                      scale = 1.0 + (_controller.value * 0.2);
                      color = AppColors.primaryBlue;
                      break;
                    case VoiceState.processing:
                      scale = 1.0;
                      color = Colors.purple;
                      break;
                    case VoiceState.speaking:
                      scale = 1.0 + (_controller.value * 0.1);
                      color = AppColors.success;
                      break;
                    case VoiceState.error:
                      color = AppColors.emergency;
                      break;
                    default:
                      scale = 1.0;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.2),
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
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          voiceState.status == VoiceState.listening
                              ? Icons.mic
                              : voiceState.status == VoiceState.processing
                              ? Icons.psychology
                              : voiceState.status == VoiceState.speaking
                              ? Icons.volume_up
                              : Icons.mic_none,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Text Display
            Text(
              _getStatusText(voiceState),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (voiceState.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  voiceState.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Error Display with Retry (New)
            if (voiceState.status == VoiceState.error)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(voiceSessionProvider.notifier).startListening();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergency,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(voiceSessionProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 24),
                if (voiceState.status == VoiceState.listening)
                  // Stop listening button (optional, usually touch to stop)
                  FloatingActionButton(
                    onPressed: () {
                      ref.read(voiceSessionProvider.notifier).stopListening();
                    },
                    backgroundColor: AppColors.emergency,
                    child: const Icon(Icons.stop),
                  )
                else
                  FloatingActionButton(
                    onPressed: () {
                      ref.read(voiceSessionProvider.notifier).startListening();
                    },
                    backgroundColor: AppColors.primaryBlue,
                    child: const Icon(Icons.mic),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getStatusText(VoiceSessionState state) {
    switch (state.status) {
      case VoiceState.initial:
        return 'Tap to Start';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.processing:
        return 'Thinking...';
      case VoiceState.speaking:
        return 'Speaking...';
      case VoiceState.error:
        return state.errorMessage ?? 'Error';
    }
  }
}
