import 'dart:convert';

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
  }) async {
    return await _apiService.post(
      ApiConfig.register,
      {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
        'location': location,
      },
    );
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return await _apiService.post(
      ApiConfig.verifyOtp,
      {
        'email': email,
        'otp': otp,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.login,
      {
        'email': email,
        'password': password,
      },
    );

    final token = response['token'] ??
        response['accessToken'];

    if (token != null) {
      await StorageService.saveToken(
        token.toString(),
      );
    }

    dynamic userData = response['user'];

    if (userData is Map<String, dynamic>) {
      final user = UserModel.fromJson(userData);

      await StorageService.saveUser(
        jsonEncode(user.toJson()),
      );
    }

    return response;
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return await _apiService.post(
      ApiConfig.forgotPassword,
      {
        'email': email,
      },
    );
  }

  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    return await _apiService.post(
      ApiConfig.verifyResetOtp,
      {
        'email': email,
        'otp': otp,
      },
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await _apiService.post(
      ApiConfig.resetPassword,
      {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _apiService.post(
        ApiConfig.logout,
        {},
        authenticated: true,
      );
    } catch (_) {
      // Even if server logout fails,
      // clear local authentication.
    }

    await StorageService.clear();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get(
        ApiConfig.me,
        authenticated: true,
      );

      final userData = response['user'];

      if (userData is Map<String, dynamic>) {
        return UserModel.fromJson(userData);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();

    return token != null && token.isNotEmpty;
  }
}