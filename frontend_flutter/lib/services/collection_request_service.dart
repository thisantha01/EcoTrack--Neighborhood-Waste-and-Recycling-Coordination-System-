import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/collection_request_model.dart';
import 'storage_service.dart';

class CollectionRequestService {
  static Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  static Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Create a new collection request
  static Future<CollectionRequest> createRequest({
    required String wasteType,
    required double estimatedQuantity,
    String description = '',
    String? imageUrl,
    required String location,
    double? lat,
    double? lng,
    DateTime? preferredDate,
    String? preferredTime,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.collectionRequests),
      headers: _headers(token!),
      body: jsonEncode({
        'wasteType': wasteType,
        'estimatedQuantity': estimatedQuantity,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'coordinates': lat != null && lng != null ? {'lat': lat, 'lng': lng} : null,
        'preferredDate': preferredDate?.toIso8601String(),
        'preferredTime': preferredTime,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success']) {
      return CollectionRequest.fromJson(data['request']);
    }
    throw Exception(data['message'] ?? 'Failed to create request');
  }

  // Get my requests
  static Future<List<CollectionRequest>> getMyRequests({String? status}) async {
    final token = await _getToken();
    String url = ApiConfig.myCollectionRequests;
    if (status != null) url += '?status=$status';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token!),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return (data['requests'] as List)
          .map((r) => CollectionRequest.fromJson(r))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch requests');
  }

  // Get all requests (for drivers)
  static Future<List<CollectionRequest>> getAllRequests({String? status}) async {
    final token = await _getToken();
    String url = ApiConfig.allCollectionRequests;
    if (status != null) url += '?status=$status';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token!),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return (data['requests'] as List)
          .map((r) => CollectionRequest.fromJson(r))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch requests');
  }

  // Get single request
  static Future<CollectionRequest> getRequest(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.collectionRequest(id)),
      headers: _headers(token!),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return CollectionRequest.fromJson(data['request']);
    }
    throw Exception(data['message'] ?? 'Failed to fetch request');
  }

  // Update status (driver/admin)
  static Future<CollectionRequest> updateStatus({
    required String id,
    required String status,
    String? note,
    String? assignedDriver,
  }) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(ApiConfig.collectionRequestStatus(id)),
      headers: _headers(token!),
      body: jsonEncode({
        'status': status,
        'note': note,
        'assignedDriver': assignedDriver,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return CollectionRequest.fromJson(data['request']);
    }
    throw Exception(data['message'] ?? 'Failed to update status');
  }

  // Cancel request
  static Future<CollectionRequest> cancelRequest(String id) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(ApiConfig.collectionRequestCancel(id)),
      headers: _headers(token!),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return CollectionRequest.fromJson(data['request']);
    }
    throw Exception(data['message'] ?? 'Failed to cancel request');
  }
}
