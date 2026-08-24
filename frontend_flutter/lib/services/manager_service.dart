import '../config/api_config.dart';
import 'api_service.dart';

class ManagerService {
  final ApiService _apiService = ApiService();

  /// Get collection requests with optional filters
  Future<Map<String, dynamic>> getCollectionRequests({
    String? status,
    String? wasteType,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{};

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (wasteType != null && wasteType.isNotEmpty) {
      queryParams['wasteType'] = wasteType;
    }
    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }
    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse(ApiConfig.managerCollectionRequests)
        .replace(queryParameters: queryParams);

    return await _apiService.get(
      uri.toString(),
      authenticated: true,
    );
  }

  /// Get single request details
  Future<Map<String, dynamic>> getRequestDetails(
    String requestId,
  ) async {
    return await _apiService.get(
      ApiConfig.managerRequestDetail(requestId),
      authenticated: true,
    );
  }

  /// Get available drivers
  Future<Map<String, dynamic>> getAvailableDrivers() async {
    return await _apiService.get(
      ApiConfig.managerAvailableDrivers,
      authenticated: true,
    );
  }

  /// Assign driver to request
  Future<Map<String, dynamic>> assignDriver({
    required String requestId,
    required String driverId,
  }) async {
    return await _apiService.post(
      ApiConfig.managerAssignDriver(requestId),
      {
        'driverId': driverId,
      },
      authenticated: true,
    );
  }
}
