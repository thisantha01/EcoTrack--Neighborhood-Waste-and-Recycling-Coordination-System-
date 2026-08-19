import 'dart:convert';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiService {
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (authenticated) {
        final token = await StorageService.getToken();

        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception(
        'Unable to connect to server: $e',
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    bool authenticated = false,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      if (authenticated) {
        final token = await StorageService.getToken();

        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception(
        'Unable to connect to server: $e',
      );
    }
  }

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'Invalid server response',
      );
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': true,
        'data': decoded,
      };
    }

    String message = 'Something went wrong';

    if (decoded is Map<String, dynamic>) {
      message = decoded['message'] ??
          decoded['error'] ??
          message;
    }

    throw Exception(message);
  }
}