import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static Future<void> saveToken(String token) async {
    await _storage.write(
      key: tokenKey,
      value: token,
    );
  }

  static Future<String?> getToken() async {
    return await _storage.read(
      key: tokenKey,
    );
  }

  static Future<void> saveUser(String userJson) async {
    await _storage.write(
      key: userKey,
      value: userJson,
    );
  }

  static Future<String?> getUser() async {
    return await _storage.read(
      key: userKey,
    );
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}