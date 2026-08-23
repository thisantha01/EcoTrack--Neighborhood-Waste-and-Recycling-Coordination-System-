import 'community_post_model.dart';

class BadgeModel {
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;

  BadgeModel({
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏅',
      earnedAt: DateTime.tryParse(json['earnedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class UserEngagement {
  final String id;
  final int points;
  final String level;
  final List<BadgeModel> badges;
  final int eventsJoined;
  final int postsCreated;
  final int reportsSubmitted;
  final double totalWasteCollected;

  UserEngagement({
    required this.id,
    required this.points,
    required this.level,
    required this.badges,
    required this.eventsJoined,
    required this.postsCreated,
    required this.reportsSubmitted,
    required this.totalWasteCollected,
  });

  factory UserEngagement.fromJson(Map<String, dynamic> json) {
    final badgesList = json['badges'] as List? ?? [];
    return UserEngagement(
      id: json['_id']?.toString() ?? '',
      points: json['points'] ?? 0,
      level: json['level'] ?? 'bronze',
      badges: badgesList
          .map((b) => BadgeModel.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
      eventsJoined: json['eventsJoined'] ?? 0,
      postsCreated: json['postsCreated'] ?? 0,
      reportsSubmitted: json['reportsSubmitted'] ?? 0,
      totalWasteCollected:
          (json['totalWasteCollected'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LeaderboardEntry {
  final UserEngagement engagement;
  final PostAuthor user;

  LeaderboardEntry({required this.engagement, required this.user});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      engagement: UserEngagement.fromJson(json),
      user: PostAuthor.fromJson(
        json['user'] is Map ? Map<String, dynamic>.from(json['user']) : {},
      ),
    );
  }
}
