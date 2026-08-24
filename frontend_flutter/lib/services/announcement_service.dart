import '../config/api_config.dart';
import '../models/announcement_model.dart';
import 'api_service.dart';

class AnnouncementService {
  final ApiService _api = ApiService();

  Future<List<Announcement>> getAnnouncements({String? type}) async {
    final url = type != null
        ? '${ApiConfig.announcements}?type=$type'
        : ApiConfig.announcements;
    final response = await _api.get(url, authenticated: true);
    final list = response['announcements'] as List? ?? [];
    return list
        .map((a) => Announcement.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    String type = 'announcement',
    String? location,
    DateTime? scheduledAt,
    List<String> targetRoles = const ['all'],
  }) async {
    final response = await _api.post(
      ApiConfig.announcements,
      {
        'title': title,
        'content': content,
        'type': type,
        if (location != null) 'location': location,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
        'targetRoles': targetRoles,
      },
      authenticated: true,
    );
    return Announcement.fromJson(
        Map<String, dynamic>.from(response['announcement']));
  }

  Future<void> deleteAnnouncement(String id) async {
    await _api.delete(ApiConfig.announcement(id), authenticated: true);
  }
}
