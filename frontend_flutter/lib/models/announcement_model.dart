import 'community_post_model.dart';

class Announcement {
  final String id;
  final PostAuthor author;
  final String title;
  final String content;
  final String type;
  final DateTime? scheduledAt;
  final String location;
  final List<String> targetRoles;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.author,
    required this.title,
    required this.content,
    required this.type,
    this.scheduledAt,
    required this.location,
    required this.targetRoles,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final rolesList = json['targetRoles'] as List? ?? [];
    return Announcement(
      id: json['_id']?.toString() ?? '',
      author: PostAuthor.fromJson(
        json['author'] is Map
            ? Map<String, dynamic>.from(json['author'])
            : {},
      ),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'announcement',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'])
          : null,
      location: json['location'] ?? '',
      targetRoles: rolesList.map((r) => r.toString()).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
