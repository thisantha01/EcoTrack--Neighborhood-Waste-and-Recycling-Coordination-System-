import '../config/api_config.dart';
import '../models/community_report_model.dart';
import 'api_service.dart';

class CommunityReportService {
  final ApiService _api = ApiService();

  Future<List<CommunityReport>> getReports({
    String? status,
    String? type,
  }) async {
    String url = ApiConfig.communityReports;
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (type != null) params.add('type=$type');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await _api.get(url, authenticated: true);
    final list = response['reports'] as List? ?? [];
    return list
        .map((r) => CommunityReport.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<CommunityReport> getReport(String id) async {
    final response =
        await _api.get(ApiConfig.communityReport(id), authenticated: true);
    return CommunityReport.fromJson(
        Map<String, dynamic>.from(response['report']));
  }

  Future<CommunityReport> createReport({
    required String title,
    required String description,
    required String location,
    String type = 'illegal_dumping',
    String? imageUrl,
    Map<String, double>? coordinates,
  }) async {
    final response = await _api.post(
      ApiConfig.communityReports,
      {
        'title': title,
        'description': description,
        'location': location,
        'type': type,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (coordinates != null) 'coordinates': coordinates,
      },
      authenticated: true,
    );
    return CommunityReport.fromJson(
        Map<String, dynamic>.from(response['report']));
  }

  Future<Map<String, dynamic>> toggleUpvote(String reportId) async {
    return await _api.post(
      ApiConfig.communityReportUpvote(reportId),
      {},
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> addAdditionalInfo(
    String reportId, {
    String? text,
    String? imageUrl,
  }) async {
    return await _api.post(
      ApiConfig.communityReportInfo(reportId),
      {
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
      authenticated: true,
    );
  }

  Future<void> updateStatus(String reportId, String status) async {
    await _api.put(
      ApiConfig.communityReportStatus(reportId),
      {'status': status},
      authenticated: true,
    );
  }
}
