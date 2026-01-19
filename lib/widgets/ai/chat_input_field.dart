import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
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
                  hintText: 'Ask me anything...',
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
          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_hasText && !widget.isLoading)
                    ? AppColors.primaryOrange
                    : (isDark ? AppColors.cardDark : const Color(0xFFE5E7EB)),
                shape: BoxShape.circle,
                boxShadow: (_hasText && !widget.isLoading)
                    ? [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
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
                      Icons.send,
                      size: 20,
                      color: (_hasText && !widget.isLoading)
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
