import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import '../models/pickup_model.dart';

class DriverService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/driver/driver_dashboard',
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
      final data = response['data'] ?? response['schedule'] ?? response['pickups'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => PickupModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return const [];
    } catch (e) {
      debugPrint('DriverService.getTodaySchedule error: $e');
      rethrow;
    }
  }

  Future<bool> updateAvailability(bool isAvailable) async {
    try {
      await _apiService.patch(
        '${ApiConfig.baseUrl}/driver/availability',
        {'isAvailable': isAvailable},
        authenticated: true,
      );
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
}
