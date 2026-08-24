import 'community_post_model.dart';

class CleanupEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final double? lat;
  final double? lng;
  final DateTime scheduledAt;
  final PostAuthor organizer;
  final List<PostAuthor> participants;
  final int maxParticipants;
  final String status;
  final double wasteCollected;
  final double wasteRecycled;
  final DateTime createdAt;

  CleanupEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.lat,
    this.lng,
    required this.scheduledAt,
    required this.organizer,
    required this.participants,
    required this.maxParticipants,
    required this.status,
    required this.wasteCollected,
    required this.wasteRecycled,
    required this.createdAt,
  });

  factory CleanupEvent.fromJson(Map<String, dynamic> json) {
    final participantsList = json['participants'] as List? ?? [];
    final coords = json['coordinates'] as Map? ?? {};

    return CleanupEvent(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      lat: (coords['lat'] as num?)?.toDouble(),
      lng: (coords['lng'] as num?)?.toDouble(),
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      organizer: PostAuthor.fromJson(
        json['organizer'] is Map
            ? Map<String, dynamic>.from(json['organizer'])
            : {},
      ),
      participants: participantsList
          .map((p) => PostAuthor.fromJson(
                p is Map ? Map<String, dynamic>.from(p) : {},
              ))
          .toList(),
      maxParticipants: json['maxParticipants'] ?? 50,
      status: json['status'] ?? 'upcoming',
      wasteCollected: (json['wasteCollected'] as num?)?.toDouble() ?? 0,
      wasteRecycled: (json['wasteRecycled'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
