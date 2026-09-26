import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import '../models/pickup_model.dart';

class DriverService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/driver/dashboard',
        authenticated: true,
      );
      final data = response['data'];
      return data is Map<String, dynamic> ? data : response;
    } catch (e) {
      debugPrint('DriverService.getDashboardOverview error: $e');
      rethrow;
    }
  }

  Future<List<PickupModel>> getTodaySchedule() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/driver/schedule/today',
        authenticated: true,
      );
      final data =
          response['data'] ?? response['schedule'] ?? response['pickups'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => PickupModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('DriverService.getTodaySchedule error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedRoutes() async {
    try {
      final response = await _apiService.get(
        ApiConfig.driverRoutes,
        authenticated: true,
      );
      final routes = response['routes'];
      if (routes is List) {
        return routes
            .whereType<Map>()
            .map((route) => Map<String, dynamic>.from(route))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('DriverService.getAssignedRoutes error: $e');
      rethrow;
    }
  }

  Future<bool> updateAvailability(bool isAvailable) async {
    try {
      await _apiService.patch('${ApiConfig.baseUrl}/driver/availability', {
        'isAvailable': isAvailable,
      }, authenticated: true);
      return true;
    } catch (e) {
      debugPrint('DriverService.updateAvailability error: $e');
      return false;
    }
  }

  Future<bool> updateStatus(String pickupId, String status) async {
    try {
      await _apiService.patch(
        '${ApiConfig.baseUrl}/driver/pickups/$pickupId/status',
        {'status': status},
        authenticated: true,
      );
      return true;
    } catch (e) {
      debugPrint('DriverService.updateStatus error: $e');
      return false;
    }
  }

  Future<bool> updatePickupDetails({
    required String pickupId,
    required double weightKg,
    required String wasteType,
    required String notes,
  }) async {
    try {
      await _apiService.patch(
        '${ApiConfig.baseUrl}/driver/pickups/$pickupId/details',
        {'weightKg': weightKg, 'wasteType': wasteType, 'notes': notes},
        authenticated: true,
      );
      return true;
    } catch (e) {
      debugPrint('DriverService.updatePickupDetails error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateRouteStopStatus({
    required String routeId,
    required String stopId,
    required int stopIndex,
    required String status,
  }) async {
    try {
      return await _apiService.patch(
        '${ApiConfig.baseUrl}/driver/routes/$routeId/stops/$stopId/status',
        {'status': status, 'stopIndex': stopIndex},
        authenticated: true,
      );
    } catch (e) {
      debugPrint('DriverService.updateRouteStopStatus error: $e');
      rethrow;
    }
  }

  Future<void> postLiveLocation({
    required double latitude,
    required double longitude,
  }) async {
    await _apiService.post(
      '${ApiConfig.baseUrl}/driver/location',
      {'lat': latitude, 'lng': longitude},
      authenticated: true,
    );
  }
}
