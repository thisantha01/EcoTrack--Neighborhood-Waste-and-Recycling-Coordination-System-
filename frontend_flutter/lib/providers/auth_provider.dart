import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;

  bool _isLoading = false;

  String? _error;

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isLoggedIn => _user != null;

  String? get role => _user?.role;

  Future<bool> login(
    String email,
    String password,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      final userData = response['user'];

      if (userData is Map<String, dynamic>) {
        _user = UserModel.fromJson(userData);
      } else {
        throw Exception(
          'User information was not returned',
        );
      }

      notifyListeners();

      return true;
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String location,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        location: location,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.verifyOtp(
        email: email,
        otp: otp,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(
    String email,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.forgotPassword(
        email: email,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: password,
      );

      return true;
    } catch (e) {
      _error = _cleanError(e);
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    _user = null;

    notifyListeners();
  }

  Future<void> checkAuthentication() async {
    final loggedIn =
        await _authService.isLoggedIn();

    if (!loggedIn) {
      _user = null;
      notifyListeners();
      return;
    }

    final user =
        await _authService.getCurrentUser();

    _user = user;

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }
}