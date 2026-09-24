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

    final uri = Uri.parse(
      ApiConfig.managerCollectionRequests,
    ).replace(queryParameters: queryParams);

    return await _apiService.get(uri.toString(), authenticated: true);
  }

  /// Get single request details
  Future<Map<String, dynamic>> getRequestDetails(String requestId) async {
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
    return await _apiService.post(ApiConfig.managerAssignDriver(requestId), {
      'driverId': driverId,
    }, authenticated: true);
  }

  /// Get fixed routes managed by the recycling manager
  Future<Map<String, dynamic>> getRoutes({int page = 1, int limit = 20}) async {
    final uri = Uri.parse(ApiConfig.managerRoutes).replace(
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );

    return await _apiService.get(uri.toString(), authenticated: true);
  }

  Future<Map<String, dynamic>> createRoute({
    required String routeName,
    required String zone,
    required DateTime date,
    String? description,
    String? assignedDriver,
    List<String> operatingDays = const [],
    String targetWasteType = 'weekly_schedule',
    List<Map<String, dynamic>> weeklyCategorySchedule = const [],
    List<Map<String, dynamic>> routeStops = const [],
    Map<String, double>? areaCoordinates,
  }) async {
    return await _apiService.post(ApiConfig.managerRoutes, {
      'routeName': routeName,
      'zone': zone,
      'date': date.toIso8601String(),
      'description': description ?? '',
      'assignedDriver': assignedDriver,
      'assignedLocations': [zone],
      'operatingDays': operatingDays,
      'targetWasteType': targetWasteType,
      'weeklyCategorySchedule': weeklyCategorySchedule,
      'routeStops': routeStops,
      'areaCoordinates': areaCoordinates ?? {'lat': 6.9061, 'lng': 79.9696},
    }, authenticated: true);
  }

  /// Add stop or waypoint to route
  Future<Map<String, dynamic>> addRouteStop({
    required String routeId,
    String? collectionRequestId,
    required double lat,
    required double lng,
    required String address,
    int? sequenceOrder,
  }) async {
    return await _apiService.patch(ApiConfig.managerRouteAddStop(routeId), {
      'collectionRequestId': ?collectionRequestId,
      'location': {'lat': lat, 'lng': lng},
      'address': address,
      'sequenceOrder': ?sequenceOrder,
    }, authenticated: true);
  }

  /// Update an existing route details and stops
  Future<Map<String, dynamic>> updateRoute({
    required String routeId,
    String? routeName,
    String? zone,
    DateTime? date,
    String? description,
    String? assignedDriver,
    List<String>? operatingDays,
    String? targetWasteType,
    List<Map<String, dynamic>>? weeklyCategorySchedule,
    List<Map<String, dynamic>>? routeStops,
    Map<String, double>? areaCoordinates,
    String? status,
  }) async {
    return await _apiService.put(ApiConfig.managerRoute(routeId), {
      'routeName': ?routeName,
      'zone': ?zone,
      'date': ?date?.toIso8601String(),
      'description': ?description,
      'assignedDriver': ?assignedDriver,
      'assignedLocations': zone != null ? [zone] : null,
      'operatingDays': ?operatingDays,
      'targetWasteType': ?targetWasteType,
      'weeklyCategorySchedule': ?weeklyCategorySchedule,
      'routeStops': ?routeStops,
      'areaCoordinates': ?areaCoordinates,
      'status': ?status,
    }, authenticated: true);
  }

  /// Delete a route by ID
  Future<Map<String, dynamic>> deleteRoute(String routeId) async {
    return await _apiService.delete(ApiConfig.managerRoute(routeId), authenticated: true);
  }

  /// Reorder stops on a route
  Future<Map<String, dynamic>> reorderRouteStops({
    required String routeId,
    required List<Map<String, dynamic>> routeStops,
  }) async {
    return await _apiService.patch(ApiConfig.managerRouteReorderStops(routeId), {
      'routeStops': routeStops,
    }, authenticated: true);
  }

  /// Update stop status (pending, collected, skipped)
  Future<Map<String, dynamic>> updateRouteStopStatus({
    required String routeId,
    required int stopIndex,
    required String status,
    String? reason,
  }) async {
    return await _apiService.patch(
      ApiConfig.managerRouteUpdateStopStatus(routeId, stopIndex),
      {
        'status': status,
        'reason': ?reason,
      },
      authenticated: true,
    );
  }

  /// Auto-optimize route sequence using physical proximity (TSP)
  Future<Map<String, dynamic>> optimizeRouteSequence(String routeId) async {
    return await _apiService.patch(
      ApiConfig.managerRouteOptimizeSequence(routeId),
      {},
      authenticated: true,
    );
  }

  /// Remove stop from route (by collectionRequestId, stopId, or sequenceOrder)
  Future<Map<String, dynamic>> removeRouteStop({
    required String routeId,
    String? collectionRequestId,
    String? stopId,
    int? sequenceOrder,
  }) async {
    return await _apiService.patch(ApiConfig.managerRouteRemoveStop(routeId), {
      'collectionRequestId': ?collectionRequestId,
      'stopId': ?stopId,
      'sequenceOrder': ?sequenceOrder,
    }, authenticated: true);
  }

  /// Confirm a collection request on a selected route
  Future<Map<String, dynamic>> confirmRequestRoute({
    required String routeId,
    required String collectionRequestId,
    required String driverId,
    required DateTime date,
    required String time,
  }) async {
    return await _apiService.patch(ApiConfig.managerRouteConfirm(routeId), {
      'collectionRequestId': collectionRequestId,
      'assignedDriver': driverId,
      'scheduledDate': date.toIso8601String(),
      'scheduledTime': time,
    }, authenticated: true);
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
    final uri = Uri.parse(
      ApiConfig.managerRouteSuggestion,
    ).replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});
    return await _apiService.get(uri.toString(), authenticated: true);
  }

  Future<Map<String, dynamic>> getPublicRouteSchedule({String? zone}) async {
    final baseUri = Uri.parse(ApiConfig.publicRouteSchedule);
    final uri = zone != null && zone.isNotEmpty
        ? baseUri.replace(queryParameters: {'zone': zone})
        : baseUri;
    return await _apiService.get(uri.toString(), authenticated: true);
  }
}
