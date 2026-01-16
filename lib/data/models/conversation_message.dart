/// Role of the conversation participant
enum MessageRole { user, assistant, system }

/// Message in AI conversation
class ConversationMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ConversationMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory ConversationMessage.user(String content) {
    return ConversationMessage(
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ConversationMessage.assistant(
    String content, {
    Map<String, dynamic>? metadata,
  }) {
    return ConversationMessage(
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  factory ConversationMessage.system(String content) {
    return ConversationMessage(
      role: MessageRole.system,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.toString().split('.').last,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      role: _parseRole(json['role'] as String),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static MessageRole _parseRole(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }
}
