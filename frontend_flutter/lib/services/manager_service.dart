import '../config/api_config.dart';
import 'api_service.dart';

class ManagerService {
  final ApiService _apiService = ApiService();

  /// Get recycling manager dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _apiService.get(
      ApiConfig.managerDashboardStats,
      authenticated: true,
    );
  }

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

  /// Get fixed routes managed by the recycling manager
  Future<Map<String, dynamic>> getRoutes({int page = 1, int limit = 20}) async {
    final uri = Uri.parse(ApiConfig.managerRoutes).replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return await _apiService.get(
      uri.toString(),
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> createRoute({
    required String routeName,
    required String zone,
    required DateTime date,
    String? description,
    String? assignedDriver,
    List<String> operatingDays = const [],
  }) async {
    return await _apiService.post(
      ApiConfig.managerRoutes,
      {
        'routeName': routeName,
        'zone': zone,
        'date': date.toIso8601String(),
        'description': description ?? '',
        'assignedDriver': assignedDriver,
        'assignedLocations': [zone],
        'operatingDays': operatingDays,
      },
      authenticated: true,
    );
  }

  /// Confirm a collection request on a selected route
  Future<Map<String, dynamic>> confirmRequestRoute({
    required String routeId,
    required String collectionRequestId,
    required String driverId,
    required DateTime date,
    required String time,
  }) async {
    return await _apiService.patch(
      ApiConfig.managerRouteConfirm(routeId),
      {
        'collectionRequestId': collectionRequestId,
        'assignedDriver': driverId,
        'scheduledDate': date.toIso8601String(),
        'scheduledTime': time,
      },
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> changeRouteDriver({
    required String routeId,
    required String driverId,
  }) async {
    return await _apiService.patch(
      ApiConfig.managerRouteChangeDriver(routeId),
      {'driverId': driverId},
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> suggestRoute({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(ApiConfig.managerRouteSuggestion).replace(
      queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
    );
    return await _apiService.get(uri.toString(), authenticated: true);
  }
}
