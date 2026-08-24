import 'dart:convert';
import 'package:http/http.dart' as http;

class RouteService {
  final String baseUrl = "http://YOUR_BACKEND_IP:5000/api/routes";

  Future<bool> createAndAssignRoute({
    required String routeName,
    required String driverId,
    required DateTime scheduledDate,
    required List<String> pickupRequestIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assign-route'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'routeName': routeName,
          'driverId': driverId,
          'scheduledDate': scheduledDate.toIso8601String(),
          'pickupRequests': pickupRequestIds,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}