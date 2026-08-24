import '../config/api_config.dart';
import '../models/engagement_model.dart';
import 'api_service.dart';

class EngagementService {
  final ApiService _api = ApiService();

  Future<UserEngagement> getMyEngagement() async {
    final response =
        await _api.get(ApiConfig.myEngagement, authenticated: true);
    return UserEngagement.fromJson(
        Map<String, dynamic>.from(response['engagement']));
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response =
        await _api.get(ApiConfig.leaderboard, authenticated: true);
    final list = response['leaderboard'] as List? ?? [];
    return list
        .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> getCommunityStats() async {
    final response =
        await _api.get(ApiConfig.communityStats, authenticated: true);
    return response['stats'] as Map<String, dynamic>? ?? {};
  }
}
