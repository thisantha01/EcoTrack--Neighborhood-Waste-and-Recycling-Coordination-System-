import 'community_post_model.dart';

class ReportAdditionalInfo {
  final String id;
  final PostAuthor user;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  ReportAdditionalInfo({
    required this.id,
    required this.user,
    required this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory ReportAdditionalInfo.fromJson(Map<String, dynamic> json) {
    return ReportAdditionalInfo(
      id: json['_id']?.toString() ?? '',
      user: PostAuthor.fromJson(
        json['user'] is Map ? Map<String, dynamic>.from(json['user']) : {},
      ),
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class CommunityReport {
  final String id;
  final PostAuthor reporter;
  final String title;
  final String description;
  final String location;
  final double? lat;
  final double? lng;
  final String? imageUrl;
  final String type;
  final String status;
  final List<String> upvotes;
  final List<ReportAdditionalInfo> additionalInfo;
  final DateTime createdAt;

  CommunityReport({
    required this.id,
    required this.reporter,
    required this.title,
    required this.description,
    required this.location,
    this.lat,
    this.lng,
    this.imageUrl,
    required this.type,
    required this.status,
    required this.upvotes,
    required this.additionalInfo,
    required this.createdAt,
  });

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    final upvotesList = json['upvotes'] as List? ?? [];
    final infoList = json['additionalInfo'] as List? ?? [];
    final coords = json['coordinates'] as Map? ?? {};

    return CommunityReport(
      id: json['_id']?.toString() ?? '',
      reporter: PostAuthor.fromJson(
        json['reporter'] is Map
            ? Map<String, dynamic>.from(json['reporter'])
            : {},
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      lat: (coords['lat'] as num?)?.toDouble(),
      lng: (coords['lng'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'],
      type: json['type'] ?? 'illegal_dumping',
      status: json['status'] ?? 'open',
      upvotes: upvotesList.map((e) => e.toString()).toList(),
      additionalInfo: infoList
          .map((i) =>
              ReportAdditionalInfo.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
