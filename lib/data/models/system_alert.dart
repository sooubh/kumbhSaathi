/// System-wide alert model for admin notifications
class SystemAlert {
  final String id;
  final String title;
  final String message;
  final String severity; // 'info', 'warning', 'critical'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const SystemAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.isActive,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'severity': severity,
      'isActive': isActive,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
      isActive: json['isActive'] ?? true,
      createdAt: (json['createdAt'] as dynamic).toDate(),
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as dynamic).toDate()
          : null,
    );
  }
}
