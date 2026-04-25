import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';

/// Text input field for chat messages
class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 4), () {
      if (_isListening) {
        _speech.stop();
        setState(() => _isListening = false);
        if (_controller.text.trim().isNotEmpty && !widget.isLoading) {
          _sendMessage();
        }
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            _silenceTimer?.cancel();
            // Automatically send if they finished dictating natively
            if (_controller.text.trim().isNotEmpty && !widget.isLoading) {
              _sendMessage();
            }
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          _silenceTimer?.cancel();
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _resetSilenceTimer(); // Start the strict silence timer
        _speech.listen(
          pauseFor: const Duration(seconds: 4), // Auto-stop after 4 seconds of silence
          onResult: (val) {
            _resetSilenceTimer(); // Reset silence strict timer on new word picked up
            setState(() {
              _controller.text = val.recognizedWords;
              // Push cursor to end
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          },
        );
      }
    } else {
      // User manually pushed Stop
      _silenceTimer?.cancel();
      setState(() => _isListening = false);
      _speech.stop();
      if (_controller.text.trim().isNotEmpty && !widget.isLoading) {
        _sendMessage();
      }
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    _silenceTimer?.cancel();
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
    if (_hasText && !widget.isLoading) {
      widget.onSendMessage(_controller.text.trim());
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.primaryOrange.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !widget.isLoading,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening (Speak now)...' : 'Ask me anything...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textDarkDark
                      : AppColors.textDarkLight,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send / Mic Button
          GestureDetector(
            onTap: _isListening ? _listen : (_hasText ? _sendMessage : _listen),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening 
                    ? AppColors.emergency 
                    : (_hasText
                        ? AppColors.primaryOrange
                        : (isDark ? AppColors.cardDark : const Color(0xFFE5E7EB))),
                shape: BoxShape.circle,
                boxShadow: (_hasText || _isListening)
                    ? [
                        BoxShadow(
                          color: _isListening 
                              ? AppColors.emergency.withValues(alpha: 0.5) 
                              : AppColors.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: widget.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? AppColors.textDarkDark : Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      _isListening ? Icons.stop : (_hasText ? Icons.send : Icons.mic_none),
                      size: 20,
                      color: (_hasText || _isListening)
                          ? Colors.white
                          : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
