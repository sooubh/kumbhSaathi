import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/voice_session_provider.dart';
import '../../screens/voice/voice_assistant_sheet.dart';

/// A floating chatbot button that provides quick access to the voice assistant
/// from any screen in the app.
class ChatbotButton extends ConsumerStatefulWidget {
  const ChatbotButton({super.key});

  @override
  ConsumerState<ChatbotButton> createState() => _ChatbotButtonState();
}

class _ChatbotButtonState extends ConsumerState<ChatbotButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceSessionProvider);
    final isActive =
        voiceState.status == VoiceState.listening ||
        voiceState.status == VoiceState.speaking ||
        voiceState.status == VoiceState.processing;

    // Adjust pulse animation based on state
    if (isActive) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const VoiceAssistantSheet(),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primaryBlue : AppColors.primaryOrange,
              boxShadow: [
                BoxShadow(
                  color:
                      (isActive
                              ? AppColors.primaryBlue
                              : AppColors.primaryOrange)
                          .withValues(alpha: 0.4),
                  blurRadius: 12 + (_pulseController.value * 8),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isActive ? Icons.graphic_eq : Icons.mic,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
