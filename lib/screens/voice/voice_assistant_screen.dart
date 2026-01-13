import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Voice assistant screen with listening animation
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isListening = false;
  String _selectedLanguage = 'English';

  final List<Map<String, dynamic>> _quickCommands = [
    {
      'icon': Icons.medical_services,
      'text': 'Nearest medical help',
      'isPrimary': true,
    },
    {'icon': Icons.water_drop, 'text': 'Find nearest ghat', 'isPrimary': false},
    {'icon': Icons.search, 'text': 'Lost & Found', 'isPrimary': false},
    {'icon': Icons.local_police, 'text': 'Police help', 'isPrimary': false},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFFCFCFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                  Text(
                    'Voice Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkDark
                          : AppColors.textDarkLight,
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 28,
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkDark : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "I'm ready for your question",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Microphone Button with Pulse Animation
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse rings
                          ...List.generate(3, (index) {
                            final size = 140.0 + (index * 60);
                            final opacity = 0.15 - (index * 0.05);
                            return Container(
                              width: size + (_pulseController.value * 20),
                              height: size + (_pulseController.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBlue.withValues(
                                  alpha:
                                      opacity *
                                      (1 - _pulseController.value * 0.5),
                                ),
                              ),
                            );
                          }),
                          // Main button
                          GestureDetector(
                            onTap: _toggleListening,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBlue,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 40,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Quick Commands
                  Text(
                    'TRY SAYING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _quickCommands.map((cmd) {
                        return _QuickCommandChip(
                          icon: cmd['icon'] as IconData,
                          text: cmd['text'] as String,
                          isPrimary: cmd['isPrimary'] as bool,
                          isDark: isDark,
                          onTap: () {
                            // TODO: Process command
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFF3F4F6),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // SOS Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/sos');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.emergency,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emergency.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.emergency,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Type Button
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardSecondaryDark
                                : const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.keyboard,
                                color: isDark
                                    ? AppColors.textDarkDark
                                    : AppColors.textDarkLight,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'TYPE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? AppColors.textDarkDark
                                      : AppColors.textDarkLight,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Language Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedLanguage = _selectedLanguage == 'English'
                                  ? 'Hindi'
                                  : 'English';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardSecondaryDark
                                  : const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.translate,
                                  color: isDark
                                      ? AppColors.textDarkDark
                                      : AppColors.textDarkLight,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedLanguage == 'English'
                                      ? 'HINDI'
                                      : 'ENGLISH',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? AppColors.textDarkDark
                                        : AppColors.textDarkLight,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Home indicator
                  Container(
                    width: 128,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCommandChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPrimary;
  final bool isDark;
  final VoidCallback? onTap;

  const _QuickCommandChip({
    required this.icon,
    required this.text,
    required this.isPrimary,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isPrimary
                ? AppColors.primaryBlue.withValues(alpha: 0.2)
                : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary
                  ? AppColors.primaryBlue
                  : (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkDark
                    : AppColors.textDarkLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
