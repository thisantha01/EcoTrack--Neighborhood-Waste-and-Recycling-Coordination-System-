import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pickup_model.dart';
import '../services/driver_service.dart';
import '../services/location_service.dart';

class DriverProvider with ChangeNotifier {
  final DriverService _driverService = DriverService();
  final LocationService _locationService = LocationService();
  Timer? _liveTrackingTimer;
  Position? _liveLocation;

  bool _isDashboardLoading = false;
  bool _isScheduleLoading = false;
  String? _errorMessage;
  bool _isAvailable = true;
  int _totalPickups = 0;
  int _completedPickups = 0;
  int _remainingPickups = 0;
  int _cancelledPickups = 0;
  double _totalCollectedWeight = 0;
  Map<String, double> _collectedByCategory = {};
  int _progressPercent = 0;
  PickupModel? _nextPickup;
  List<PickupModel> _scheduleList = [];
  List<Map<String, dynamic>> _assignedRoutes = [];
  bool _isRoutesLoading = false;

  bool get isDashboardLoading => _isDashboardLoading;
  bool get isScheduleLoading => _isScheduleLoading;
  String? get errorMessage => _errorMessage;
  bool get isAvailable => _isAvailable;
  int get totalPickups => _totalPickups;
  int get completedPickups => _completedPickups;
  int get remainingPickups => _remainingPickups;
  int get cancelledPickups => _cancelledPickups;
  double get totalCollectedWeight => _totalCollectedWeight;
  Map<String, double> get collectedByCategory =>
      Map.unmodifiable(_collectedByCategory);
  int get progressPercent => _progressPercent;
  PickupModel? get nextPickup => _nextPickup;
  List<PickupModel> get scheduleList => List.unmodifiable(_scheduleList);
  List<Map<String, dynamic>> get assignedRoutes =>
      List.unmodifiable(_assignedRoutes);
  bool get isRoutesLoading => _isRoutesLoading;
  Position? get liveLocation => _liveLocation;

  Future<void> fetchAssignedRoutes() async {
    _isRoutesLoading = true;
    notifyListeners();
    try {
      _assignedRoutes = await _driverService.getAssignedRoutes();
    } catch (e) {
      debugPrint('DriverProvider.fetchAssignedRoutes error: $e');
    } finally {
      _isRoutesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardData() async {
    _isDashboardLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _driverService.getDashboardOverview();
      _isAvailable = res['isAvailable'] as bool? ?? _isAvailable;
      final metrics = res['metrics'] is Map
          ? Map<String, dynamic>.from(res['metrics'])
          : const <String, dynamic>{};
      _isAvailable = res['driver'] is Map
          ? (res['driver']['isAvailable'] as bool? ?? _isAvailable)
          : _isAvailable;
      _totalPickups = (metrics['totalPickups'] as num?)?.toInt() ?? 0;
      _completedPickups = (metrics['completedPickups'] as num?)?.toInt() ?? 0;
      _remainingPickups = (metrics['remainingPickups'] as num?)?.toInt() ?? 0;
      _cancelledPickups = (metrics['cancelledPickups'] as num?)?.toInt() ?? 0;
      _totalCollectedWeight =
          (metrics['totalCollectedWeight'] as num?)?.toDouble() ?? 0;
      _progressPercent = (metrics['progressPercent'] as num?)?.toInt() ?? 0;
      final categories = metrics['collectedByCategory'];
      _collectedByCategory = categories is Map
          ? categories.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0),
            )
          : {};

      final todays = res['todayPickups'];
      if (todays is List) {
        _scheduleList = todays
            .whereType<Map>()
            .map(
              (item) => PickupModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      final routes = res['routes'];
      _assignedRoutes = routes is List
          ? routes
                .whereType<Map>()
                .map((route) => Map<String, dynamic>.from(route))
                .toList()
          : [];

      final nextPickup = res['nextPickup'];
      _nextPickup = nextPickup is Map
          ? PickupModel.fromJson(Map<String, dynamic>.from(nextPickup))
          : _scheduleList.cast<PickupModel?>().firstWhere(
              (pickup) =>
                  pickup != null &&
                  ![
                    'completed',
                    'collected',
                    'cancelled',
                  ].contains(pickup.status),
              orElse: () => null,
            );
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
      _errorMessage =
          'Unable to load today\'s schedule. Pull down to try again.';
    } finally {
      if (!silent) {
        _isScheduleLoading = false;
        notifyListeners();
      }
    }
  }

  void _calculateStatsFromSchedule() {
    _totalPickups = _scheduleList.length;
    final completed = _scheduleList
        .where((pickup) => ['completed', 'collected'].contains(pickup.status))
        .toList();
    _completedPickups = completed.length;
    _cancelledPickups = _scheduleList
        .where((pickup) => pickup.status == 'cancelled')
        .length;
    _remainingPickups = (_totalPickups - _completedPickups - _cancelledPickups)
        .clamp(0, _totalPickups);
    _progressPercent = _totalPickups == 0
        ? 0
        : ((_completedPickups / _totalPickups) * 100).round();
    _collectedByCategory = {};
    _totalCollectedWeight = 0;
    for (final pickup in completed) {
      final category = pickup.wasteType.trim().toLowerCase();
      final key = category.isEmpty ? 'other' : category;
      _collectedByCategory.update(
        key,
        (weight) => weight + pickup.weightKg,
        ifAbsent: () => pickup.weightKg,
      );
      _totalCollectedWeight += pickup.weightKg;
    }
    if (_scheduleList.isEmpty) {
      _nextPickup = null;
      return;
    }
    _nextPickup = _scheduleList.cast<PickupModel?>().firstWhere(
      (pickup) =>
          pickup != null &&
          !['completed', 'collected', 'cancelled'].contains(pickup.status),
      orElse: () => null,
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

  Future<bool> startPickup(String pickupId) =>
      updatePickupStatus(pickupId, 'accepted');

  Future<bool> completePickup(String pickupId) =>
      updatePickupStatus(pickupId, 'completed');

  Future<bool> updatePickupStatus(String pickupId, String status) async {
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

  Future<bool> updatePickupDetails({
    required String pickupId,
    required double weightKg,
    required String wasteType,
    required String notes,
  }) async {
    final updated = await _driverService.updatePickupDetails(
      pickupId: pickupId,
      weightKg: weightKg,
      wasteType: wasteType,
      notes: notes,
    );
    if (!updated) {
      _errorMessage = 'Could not save pickup details. Please try again.';
      notifyListeners();
      return false;
    }

    final index = _scheduleList.indexWhere((pickup) => pickup.id == pickupId);
    if (index != -1) {
      _scheduleList[index] = _scheduleList[index].copyWith(
        weightKg: weightKg,
        wasteType: wasteType,
        notes: notes,
      );
    }
    await fetchDashboardData();
    notifyListeners();
    return true;
  }

  Future<bool> updateRouteStopStatus({
    required String routeId,
    String? stopId,
    int? stopIndex,
    required String status,
    String? reason,
  }) async {
    final routeIndex = _assignedRoutes.indexWhere(
      (r) => r['_id']?.toString() == routeId,
    );
    List<Map<String, dynamic>>? previousStops;
    try {
      if (routeIndex == -1) return false;
      final route = Map<String, dynamic>.from(_assignedRoutes[routeIndex]);
      final rawStops = (route['routeStops'] as List?) ?? const [];
      final legacyStops = (route['stops'] as List?) ?? const [];
      final sourceStops = rawStops.isNotEmpty ? rawStops : legacyStops;
      final stops = sourceStops
          .whereType<Map>()
          .map((stop) => Map<String, dynamic>.from(stop))
          .toList();
      final resolvedStopIndex = stopId != null
          ? stops.indexWhere((stop) => stop['_id']?.toString() == stopId)
          : stopIndex ?? -1;
      if (resolvedStopIndex < 0 || resolvedStopIndex >= stops.length) {
        return false;
      }
      final resolvedStopId = stops[resolvedStopIndex]['_id']?.toString() ?? '';
      if (resolvedStopId.isEmpty) return false;

      previousStops = stops.map(Map<String, dynamic>.from).toList();
      stops[resolvedStopIndex]['status'] = status;
      route['routeStops'] = stops;
      route['stops'] = stops;
      _assignedRoutes[routeIndex] = route;
      notifyListeners();

      final response = await _driverService.updateRouteStopStatus(
        routeId: routeId,
        stopId: resolvedStopId,
        stopIndex: resolvedStopIndex,
        status: status,
      );
      final confirmedStops = response['routeStops'];
      if (confirmedStops is List) {
        final confirmedRoute = Map<String, dynamic>.from(
          _assignedRoutes[routeIndex],
        );
        confirmedRoute['routeStops'] = confirmedStops;
        confirmedRoute['stops'] = confirmedStops;
        _assignedRoutes[routeIndex] = confirmedRoute;
        notifyListeners();
      }
      return response['success'] == true;
    } catch (e) {
      debugPrint('DriverProvider.updateRouteStopStatus error: $e');
      if (routeIndex != -1 && previousStops != null) {
        final route = Map<String, dynamic>.from(_assignedRoutes[routeIndex]);
        route['routeStops'] = previousStops;
        route['stops'] = previousStops;
        _assignedRoutes[routeIndex] = route;
        notifyListeners();
      }
      return false;
    }
  }

  Future<void> startLiveTracking() async {
    if (_liveTrackingTimer != null) return;
    if (!await _locationService.ensurePermission()) {
      _errorMessage =
          'Location permission is required for live route tracking.';
      notifyListeners();
      return;
    }
    await _sendLiveLocation();
    _liveTrackingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sendLiveLocation(),
    );
  }

  void stopLiveTracking() {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = null;
  }

  Future<void> _sendLiveLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _liveLocation = position;
      notifyListeners();
      await _driverService.postLiveLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('DriverProvider._sendLiveLocation error: $e');
    }
  }

  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }
}
