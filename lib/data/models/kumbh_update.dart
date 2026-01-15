/// Kumbh Mela event/update model
class KumbhUpdate {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String? eventTimeStart;
  final String? eventTimeEnd;
  final String category; // 'ritual', 'snan', 'announcement', 'emergency'
  final String? location;
  final bool isImportant;
  final String? imageUrl;
  final DateTime createdAt;

  KumbhUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    this.eventTimeStart,
    this.eventTimeEnd,
    required this.category,
    this.location,
    this.isImportant = false,
    this.imageUrl,
    required this.createdAt,
  });

  factory KumbhUpdate.fromJson(Map<String, dynamic> json) {
    return KumbhUpdate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      eventTimeStart: json['eventTimeStart'] as String?,
      eventTimeEnd: json['eventTimeEnd'] as String?,
      category: json['category'] as String,
      location: json['location'] as String?,
      isImportant: json['isImportant'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'eventTimeStart': eventTimeStart,
      'eventTimeEnd': eventTimeEnd,
      'category': category,
      'location': location,
      'isImportant': isImportant,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${eventDate.day} ${months[eventDate.month - 1]} ${eventDate.year}';
  }

  String get formattedTime {
    if (eventTimeStart == null) return '';
    if (eventTimeEnd == null) return eventTimeStart!;
    return '$eventTimeStart - $eventTimeEnd';
  }

  String get categoryEmoji {
    switch (category) {
      case 'ritual':
        return '🕉️';
      case 'snan':
        return '🌊';
      case 'announcement':
        return '📢';
      case 'emergency':
        return '🚨';
      default:
        return '📅';
    }
  }
}
