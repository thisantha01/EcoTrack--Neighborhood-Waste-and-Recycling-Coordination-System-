import 'package:flutter/material.dart';

import '../models/collection_request_model.dart';
import '../models/driver_assignment_model.dart';
import '../services/manager_service.dart';

class ManagerProvider extends ChangeNotifier {
  final ManagerService _managerService = ManagerService();

  // Collection Requests
  List<CollectionRequest> _requests = [];
  int _totalRequests = 0;
  int _currentPage = 1;
  bool _hasMore = true;

  // Current request detail
  CollectionRequest? _selectedRequest;
  DriverAssignmentModel? _selectedRequestAssignment;

  // Available drivers
  List<Map<String, dynamic>> _availableDrivers = [];

  // Filters
  String? _filterStatus;
  String? _filterWasteType;
  String? _filterDate;

  // Loading states
  bool _isLoadingRequests = false;
  bool _isLoadingRequestDetail = false;
  bool _isLoadingDrivers = false;
  bool _isAssigning = false;

  String? _error;

  // Getters
  List<CollectionRequest> get requests => _requests;
  int get totalRequests => _totalRequests;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  CollectionRequest? get selectedRequest => _selectedRequest;
  DriverAssignmentModel? get selectedRequestAssignment =>
      _selectedRequestAssignment;
  List<Map<String, dynamic>> get availableDrivers => _availableDrivers;
  String? get filterStatus => _filterStatus;
  String? get filterWasteType => _filterWasteType;
  String? get filterDate => _filterDate;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingRequestDetail => _isLoadingRequestDetail;
  bool get isLoadingDrivers => _isLoadingDrivers;
  bool get isAssigning => _isAssigning;
  String? get error => _error;

  // =====================================================
  // FETCH COLLECTION REQUESTS
  // =====================================================

  Future<void> fetchCollectionRequests({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _requests = [];
      _hasMore = true;
    }

    if (_isLoadingRequests) return;
    _isLoadingRequests = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _managerService.getCollectionRequests(
        status: _filterStatus,
        wasteType: _filterWasteType,
        date: _filterDate,
        page: _currentPage,
        limit: 20,
      );

      final List<dynamic> requestData = response['requests'] ?? [];
      final List<CollectionRequest> newRequests = requestData
          .map((r) => CollectionRequest.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      final pagination = response['pagination'] as Map<String, dynamic>?;
      final int total = pagination?['total'] ?? 0;

      if (refresh) {
        _requests = newRequests;
      } else {
        _requests = [..._requests, ...newRequests];
      }

      _totalRequests = total;
      _hasMore = _requests.length < _totalRequests;
      _currentPage++;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  // =====================================================
  // FETCH SINGLE REQUEST DETAIL
  // =====================================================

  Future<void> fetchRequestDetail(String requestId) async {
    _isLoadingRequestDetail = true;
    _error = null;
    _selectedRequest = null;
    _selectedRequestAssignment = null;
    notifyListeners();

    try {
      final response = await _managerService.getRequestDetails(requestId);

      final requestData = response['request'];
      if (requestData is Map<String, dynamic>) {
        _selectedRequest = CollectionRequest.fromJson(requestData);

        final assignmentData = requestData['assignment'];
        if (assignmentData is Map<String, dynamic>) {
          _selectedRequestAssignment = DriverAssignmentModel.fromJson(
            assignmentData,
          );
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingRequestDetail = false;
      notifyListeners();
    }
  }

  // =====================================================
  // FETCH AVAILABLE DRIVERS
  // =====================================================

  Future<void> fetchAvailableDrivers() async {
    _isLoadingDrivers = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _managerService.getAvailableDrivers();

      final List<dynamic> driverData = response['drivers'] ?? [];
      _availableDrivers = driverData
          .map((d) => Map<String, dynamic>.from(d))
          .toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingDrivers = false;
      notifyListeners();
    }
  }

  // =====================================================
  // ASSIGN DRIVER
  // =====================================================

  Future<bool> assignDriver({
    required String requestId,
    required String driverId,
  }) async {
    _isAssigning = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _managerService.assignDriver(
        requestId: requestId,
        driverId: driverId,
      );

      // Update the selected request if it matches
      if (_selectedRequest != null && _selectedRequest!.id == requestId) {
        final requestData = response['request'];
        if (requestData is Map<String, dynamic>) {
          _selectedRequest = CollectionRequest.fromJson(requestData);
        }

        final assignmentData = response['assignment'];
        if (assignmentData is Map<String, dynamic>) {
          _selectedRequestAssignment = DriverAssignmentModel.fromJson(
            assignmentData,
          );
        }
      }

      // Also update in the list
      final index = _requests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        final requestData = response['request'];
        if (requestData is Map<String, dynamic>) {
          _requests[index] = CollectionRequest.fromJson(requestData);
        }
      }

      _isAssigning = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isAssigning = false;
      notifyListeners();
      return false;
    }
  }

  // =====================================================
  // FILTERS
  // =====================================================

  void setFilter({String? status, String? wasteType, String? date}) {
    _filterStatus = status;
    _filterWasteType = wasteType;
    _filterDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _filterStatus = null;
    _filterWasteType = null;
    _filterDate = null;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _filterStatus != null || _filterWasteType != null || _filterDate != null;

  // =====================================================
  // CLEAR
  // =====================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedRequest() {
    _selectedRequest = null;
    _selectedRequestAssignment = null;
    notifyListeners();
  }
}
