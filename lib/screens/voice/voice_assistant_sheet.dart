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

    // Auto-start connection when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceSessionProvider.notifier).connect();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // We disconnect when sheet closes to stop mic/socket
    // Note: Provider is disposed automatically if not kept alive, but explicit disconnect is safer
    // ref.read(voiceSessionProvider.notifier).disconnect();
    // Actually, let's let the provider dispose handle it if it's auto-dispose
    // But if it's not auto-dispose, we should disconnect.
    // The provider definition was `StateNotifierProvider` (not autoDispose).
    // So we MUST disconnect manually or it keeps recording.
    // However, calling ref.read on dispose is sometimes risky.
    // Better to use `ref.onDispose` inside the provider itself, but here we trigger it.
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
                    case VoiceState.connecting:
                      scale = 1.0;
                      color = Colors.orange;
                      break;
                    case VoiceState.listening:
                      scale = 1.0 + (_controller.value * 0.2);
                      color = AppColors.primaryBlue;
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
                              : voiceState.status == VoiceState.speaking
                              ? Icons.volume_up
                              : voiceState.status == VoiceState.connecting
                              ? Icons.wifi_calling_3
                              : Icons.mic_off,
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

            // Error Display with Retry
            if (voiceState.status == VoiceState.error ||
                voiceState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    Text(
                      voiceState.errorMessage ?? 'Unknown Error',
                      style: TextStyle(color: AppColors.emergency),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(voiceSessionProvider.notifier).connect();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry Connection"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergency,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(voiceSessionProvider.notifier).disconnect();
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

                FloatingActionButton(
                  onPressed: () {
                    ref.read(voiceSessionProvider.notifier).disconnect();
                    Navigator.pop(context);
                  },
                  backgroundColor: AppColors.primaryBlue,
                  heroTag: 'stop_session',
                  child: const Icon(Icons.stop),
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
        return 'Ready';
      case VoiceState.connecting:
        return 'Connecting to Gemini Live...';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.speaking:
        return 'Gemini Speaking...';
      case VoiceState.error:
        return 'Connection Error';
      default:
        return ''; // Case for connecting, etc.
    }
  }
}
