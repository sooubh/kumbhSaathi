import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice_ai_provider.dart';
import '../../core/theme/app_colors.dart';

/// Screen for Gemini Native Audio (Live API) Interaction
class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiState = ref.watch(voiceAIProvider);

    final isConnected =
        aiState.isListening || aiState.isSpeaking || aiState.isProcessing;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark, context),

            // Main Content - Visualizer
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildVisualizer(aiState),
                    const SizedBox(height: 40),
                    _buildStatusText(aiState, isDark),
                  ],
                ),
              ),
            ),

            // Controls
            _buildBottomControls(isConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Kumbh Live Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildVisualizer(VoiceAIState aiState) {
    // Pulse faster if speaking, slower if listening
    if (aiState.isSpeaking) {
      _pulseController.duration = const Duration(milliseconds: 1000);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else if (aiState.isListening) {
      _pulseController.duration = const Duration(milliseconds: 2000);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }

    final isActive = aiState.isListening || aiState.isSpeaking;
    final baseColor = aiState.isSpeaking
        ? AppColors.primaryBlue
        : (aiState.isListening ? AppColors.emergency : Colors.grey);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              ...List.generate(3, (index) {
                final size = 200.0 + (index * 60);
                final opacity = 0.2 - (index * 0.05);
                return Container(
                  width: size + (_pulseController.value * 40),
                  height: size + (_pulseController.value * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor.withValues(alpha: opacity),
                  ),
                );
              }),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? baseColor
                    : Colors.grey.withValues(alpha: 0.1),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: baseColor.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                aiState.isSpeaking
                    ? Icons.graphic_eq
                    : (aiState.isListening ? Icons.mic : Icons.mic_off),
                size: 64,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusText(VoiceAIState aiState, bool isDark) {
    String text = 'Tap to Connect';
    Color color = isDark ? Colors.white54 : Colors.black54;

    if (aiState.isProcessing) {
      text = 'Connecting...';
      color = Colors.orange;
    } else if (aiState.isSpeaking) {
      text = 'Speaking...';
      color = AppColors.primaryBlue;
    } else if (aiState.isListening) {
      text = 'Listening...';
      color = AppColors.emergency;
    } else if (aiState.error != null) {
      text = aiState.error!;
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isConnected) {
    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      child: GestureDetector(
        onTap: _toggleSession,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.red : AppColors.primaryBlue,
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.red : AppColors.primaryBlue)
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isConnected ? Icons.call_end : Icons.call,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _toggleSession() {
    ref.read(voiceAIProvider.notifier).toggleSession();
  }
}
