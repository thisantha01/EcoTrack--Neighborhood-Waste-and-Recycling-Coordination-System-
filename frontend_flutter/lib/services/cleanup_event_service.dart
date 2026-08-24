import '../config/api_config.dart';
import '../models/cleanup_event_model.dart';
import 'api_service.dart';

class CleanupEventService {
  final ApiService _api = ApiService();

  Future<List<CleanupEvent>> getEvents({String? status}) async {
    final url = status != null
        ? '${ApiConfig.cleanupEvents}?status=$status'
        : ApiConfig.cleanupEvents;
    final response = await _api.get(url, authenticated: true);
    final list = response['events'] as List? ?? [];
    return list
        .map((e) => CleanupEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CleanupEvent> getEvent(String id) async {
    final response =
        await _api.get(ApiConfig.cleanupEvent(id), authenticated: true);
    return CleanupEvent.fromJson(
        Map<String, dynamic>.from(response['event']));
  }

  Future<CleanupEvent> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime scheduledAt,
    Map<String, double>? coordinates,
    int maxParticipants = 50,
  }) async {
    final response = await _api.post(
      ApiConfig.cleanupEvents,
      {
        'title': title,
        'description': description,
        'location': location,
        'scheduledAt': scheduledAt.toIso8601String(),
        if (coordinates != null) 'coordinates': coordinates,
        'maxParticipants': maxParticipants,
      },
      authenticated: true,
    );
    return CleanupEvent.fromJson(Map<String, dynamic>.from(response['event']));
  }

  Future<Map<String, dynamic>> toggleJoin(String eventId) async {
    return await _api.post(
      ApiConfig.cleanupEventJoin(eventId),
      {},
      authenticated: true,
    );
  }

  Future<void> updateStatus(
    String eventId,
    String status, {
    double? wasteCollected,
    double? wasteRecycled,
  }) async {
    await _api.put(
      ApiConfig.cleanupEventStatus(eventId),
      {
        'status': status,
        if (wasteCollected != null) 'wasteCollected': wasteCollected,
        if (wasteRecycled != null) 'wasteRecycled': wasteRecycled,
      },
      authenticated: true,
    );
  }
}
