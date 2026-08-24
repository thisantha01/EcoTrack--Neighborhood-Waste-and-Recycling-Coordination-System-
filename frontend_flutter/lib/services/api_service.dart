import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiService {
  // 10-second timeout for all requests
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    try {
      final headers = await _buildHeaders(authenticated);

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Make sure the backend is running and '
        'your phone is on the same Wi-Fi network as your PC.',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Check that the server IP in api_config.dart '
        'matches your PC\'s local IP address (run ipconfig to verify).',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    bool authenticated = false,
  }) async {
    try {
      final headers = await _buildHeaders(authenticated);

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Make sure the backend is running and '
        'your phone is on the same Wi-Fi network as your PC.',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Check that the server IP in api_config.dart '
        'matches your PC\'s local IP address (run ipconfig to verify).',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    try {
      final headers = await _buildHeaders(authenticated);

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Make sure the backend is running and '
        'your phone is on the same Wi-Fi network as your PC.',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Check that the server IP in api_config.dart '
        'matches your PC\'s local IP address (run ipconfig to verify).',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> delete(
    String url, {
    bool authenticated = false,
  }) async {
    try {
      final headers = await _buildHeaders(authenticated);

      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Make sure the backend is running and '
        'your phone is on the same Wi-Fi network as your PC.',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timed out. Check that the server IP in api_config.dart '
        'matches your PC\'s local IP address (run ipconfig to verify).',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to connect to server: $e');
    }
  }

  Future<Map<String, String>> _buildHeaders(bool authenticated) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': true, 'data': decoded};
    }

    String message = 'Something went wrong';

    if (decoded is Map<String, dynamic>) {
      message = decoded['message'] ?? decoded['error'] ?? message;
    }

    throw Exception(message);
  }
}