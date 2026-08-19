import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Secure storage instance
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // ============================================================
  // TOKEN
  // ============================================================

  /// Save JWT authentication token
  static Future<void> saveToken(String token) async {
    await _storage.write(
      key: tokenKey,
      value: token,
    );
  }

  /// Get saved JWT authentication token
  static Future<String?> getToken() async {
    return await _storage.read(
      key: tokenKey,
    );
  }

  /// Delete JWT authentication token
  static Future<void> clearToken() async {
    await _storage.delete(
      key: tokenKey,
    );
  }

  // ============================================================
  // USER DATA
  // ============================================================

  /// Save user information as JSON string
  static Future<void> saveUser(String userJson) async {
    await _storage.write(
      key: userKey,
      value: userJson,
    );
  }

  /// Get saved user information
  static Future<String?> getUser() async {
    return await _storage.read(
      key: userKey,
    );
  }

  /// Delete saved user information
  static Future<void> clearUser() async {
    await _storage.delete(
      key: userKey,
    );
  }

  // ============================================================
  // LOGIN CHECK
  // ============================================================

  /// Check whether a JWT token exists
  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  /// Clear authentication data
  static Future<void> logout() async {
    await _storage.delete(
      key: tokenKey,
    );

    await _storage.delete(
      key: userKey,
    );
  }

  // ============================================================
  // CLEAR EVERYTHING
  // ============================================================

  /// Delete all data stored by this application
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}