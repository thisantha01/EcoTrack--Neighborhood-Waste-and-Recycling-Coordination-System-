import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getNotifications() async {
    final response = await _apiService.get(
      ApiConfig.notifications,
      authenticated: true,
    );

    final rawList = (response['notifications'] as List?) ?? [];
    final notifications = rawList
        .whereType<Map>()
        .map((n) => AppNotification.fromJson(Map<String, dynamic>.from(n)))
        .toList();

    final unreadCount = (response['unreadCount'] as num?)?.toInt() ?? 0;

    return {
      'notifications': notifications,
      'unreadCount': unreadCount,
    };
  }

  Future<bool> markAsRead(String id) async {
    try {
      await _apiService.patch(
        ApiConfig.notificationMarkRead(id),
        {},
        authenticated: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiService.patch(
        ApiConfig.notificationsReadAll,
        {},
        authenticated: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _apiService.delete(
        ApiConfig.notificationDelete(id),
        authenticated: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
