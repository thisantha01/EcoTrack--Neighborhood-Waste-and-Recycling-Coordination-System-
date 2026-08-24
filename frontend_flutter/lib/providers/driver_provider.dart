import 'package:flutter/material.dart';
import '../models/pickup_model.dart';
import '../services/driver_service.dart';

class DriverProvider with ChangeNotifier {
  final DriverService _driverService = DriverService();

  bool _isDashboardLoading = false;
  bool _isScheduleLoading = false;
  String? _errorMessage;
  bool _isAvailable = true;
  int _totalPickups = 0;
  int _completedPickups = 0;
  int _remainingPickups = 0;
  PickupModel? _nextPickup;
  List<PickupModel> _scheduleList = [];

  bool get isDashboardLoading => _isDashboardLoading;
  bool get isScheduleLoading => _isScheduleLoading;
  String? get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  int get totalPickups => _totalPickups;
  int get completedPickups => _completedPickups;
  int get remainingPickups => _remainingPickups;
  PickupModel? get nextPickup => _nextPickup;
  List<PickupModel> get scheduleList => List.unmodifiable(_scheduleList);

  Future<void> fetchDashboardData() async {
    _isDashboardLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _driverService.getDashboardOverview();
      _isAvailable = res['isAvailable'] as bool? ?? _isAvailable;
      _totalPickups = (res['totalPickups'] as num?)?.toInt() ?? 0;
      _completedPickups = (res['completedPickups'] as num?)?.toInt() ?? 0;
      _remainingPickups = (res['remainingPickups'] as num?)?.toInt() ?? 0;

      final nextPickup = res['nextPickup'];
      if (nextPickup is Map) {
        _nextPickup = PickupModel.fromJson(Map<String, dynamic>.from(nextPickup));
      } else {
        await fetchTodaySchedule(silent: true);
        _calculateStatsFromSchedule();
      }
    } catch (e) {
      debugPrint('DriverProvider.fetchDashboardData error: $e');
      _errorMessage = 'Unable to load the dashboard. Pull down to try again.';
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTodaySchedule({bool silent = false}) async {
    if (!silent) {
      _isScheduleLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      _scheduleList = await _driverService.getTodaySchedule();
      _calculateStatsFromSchedule();
    } catch (e) {
      debugPrint('DriverProvider.fetchTodaySchedule error: $e');
      _errorMessage = 'Unable to load today\'s schedule. Pull down to try again.';
    } finally {
      if (!silent) {
        _isScheduleLoading = false;
        notifyListeners();
      }
    }
  }

  void _calculateStatsFromSchedule() {
    _totalPickups = _scheduleList.length;
    _completedPickups = _scheduleList.where((p) => p.status == 'completed').length;
    _remainingPickups = _totalPickups - _completedPickups;
    if (_scheduleList.isEmpty) {
      _nextPickup = null;
      return;
    }
    _nextPickup = _scheduleList.firstWhere(
      (p) => p.status == 'accepted' || p.status == 'scheduled',
      orElse: () => _scheduleList.first,
    );
  }

  Future<bool> toggleAvailability() async {
    final previousValue = _isAvailable;
    _isAvailable = !previousValue;
    notifyListeners();
    final wasUpdated = await _driverService.updateAvailability(_isAvailable);
    if (!wasUpdated) {
      _isAvailable = previousValue;
      _errorMessage = 'Could not update availability. Please try again.';
      notifyListeners();
    }
    return wasUpdated;
  }

  Future<bool> startPickup(String pickupId) => _updatePickupStatus(pickupId, 'accepted');

  Future<bool> completePickup(String pickupId) =>
      _updatePickupStatus(pickupId, 'completed');

  Future<bool> _updatePickupStatus(String pickupId, String status) async {
    final wasUpdated = await _driverService.updateStatus(pickupId, status);
    if (!wasUpdated) {
      _errorMessage = 'Could not update the pickup. Please try again.';
      notifyListeners();
      return false;
    }

    final index = _scheduleList.indexWhere((p) => p.id == pickupId);
    if (index != -1) {
      _scheduleList[index] = _scheduleList[index].copyWith(status: status);
      _calculateStatsFromSchedule();
      notifyListeners();
    }
    return true;
  }
}
