import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  // Android emulator uses 10.0.2.2 to reach host localhost.
  // Windows desktop and Chrome use localhost directly.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://192.168.8.104:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static String get register => '$baseUrl/auth/register';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get verifyResetOtp => '$baseUrl/auth/verify-reset-otp';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get me => '$baseUrl/auth/me';
}