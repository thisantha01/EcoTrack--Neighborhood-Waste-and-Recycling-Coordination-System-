import '../config/api_config.dart';
import 'api_service.dart';

class RouteService {
  final ApiService _apiService = ApiService();

  /// Create a route with name, zone, date, assigned driver, and waypoint array
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

  /// Get routes with optional pagination
  Future<Map<String, dynamic>> getRoutes({int page = 1, int limit = 50}) async {
    final uri = Uri.parse(ApiConfig.managerRoutes).replace(
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    return await _apiService.get(uri.toString(), authenticated: true);
  }

  /// Get single route by ID
  Future<Map<String, dynamic>> getRoute(String id) async {
    return await _apiService.get(ApiConfig.managerRoute(id), authenticated: true);
  }

  /// Add a waypoint or request stop to an existing route
  Future<Map<String, dynamic>> addStop({
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

  /// Update route details and waypoints
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

  /// Delete route
  Future<Map<String, dynamic>> deleteRoute(String routeId) async {
    return await _apiService.delete(ApiConfig.managerRoute(routeId), authenticated: true);
  }

  /// Reorder stops sequence on route
  Future<Map<String, dynamic>> reorderStops({
    required String routeId,
    required List<Map<String, dynamic>> routeStops,
  }) async {
    return await _apiService.patch(ApiConfig.managerRouteReorderStops(routeId), {
      'routeStops': routeStops,
    }, authenticated: true);
  }

  /// Update stop status (pending, collected, skipped)
  Future<Map<String, dynamic>> updateStopStatus({
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

  /// Remove a stop from a route (by collectionRequestId, stopId, or sequenceOrder)
  Future<Map<String, dynamic>> removeStop({
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

  /// Change assigned driver for a route
  Future<Map<String, dynamic>> changeDriver({
    required String routeId,
    required String driverId,
  }) async {
    return await _apiService.patch(
      ApiConfig.managerRouteChangeDriver(routeId),
      {'driverId': driverId},
      authenticated: true,
    );
  }

  /// Confirm a collection request on a route
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

  /// Find nearest active route for coordinates
  Future<Map<String, dynamic>> suggestRoute({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      ApiConfig.managerRouteSuggestion,
    ).replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});
    return await _apiService.get(uri.toString(), authenticated: true);
  }

  /// Legacy helper for assigning routes
  Future<bool> createAndAssignRoute({
    required String routeName,
    required String driverId,
    required DateTime scheduledDate,
    required List<String> pickupRequestIds,
  }) async {
    try {
      final res = await createRoute(
        routeName: routeName,
        zone: 'Malabe',
        date: scheduledDate,
        assignedDriver: driverId,
      );
      final routeId = res['route']?['_id']?.toString();
      if (routeId == null) return false;

      for (final reqId in pickupRequestIds) {
        await confirmRequestRoute(
          routeId: routeId,
          collectionRequestId: reqId,
          driverId: driverId,
          date: scheduledDate,
          time: '09:00 AM',
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}