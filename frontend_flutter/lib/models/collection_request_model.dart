import 'package:flutter/material.dart';

class RequesterInfo {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? location;

  RequesterInfo({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.location,
  });

  factory RequesterInfo.fromJson(Map<String, dynamic> json) {
    return RequesterInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      location: json['location'],
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String? phone;
  final String? vehicleType;

  DriverInfo({
    required this.id,
    required this.name,
    this.phone,
    this.vehicleType,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      vehicleType: json['vehicleType'],
    );
  }
}

class StatusHistoryEntry {
  final String status;
  final DateTime? timestamp;
  final String note;

  StatusHistoryEntry({
    required this.status,
    this.timestamp,
    this.note = '',
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      note: json['note'] ?? '',
    );
  }
}

class CollectionRequestModel {
  final String id;
  final RequesterInfo? requester;
  final String wasteType;
  final double estimatedQuantity;
  final String description;
  final String? imageUrl;
  final String location;
  final DateTime? preferredDate;
  final String preferredTime;
  final String status;
  final List<StatusHistoryEntry> statusHistory;
  final DriverInfo? assignedDriver;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CollectionRequestModel({
    required this.id,
    this.requester,
    required this.wasteType,
    this.estimatedQuantity = 0,
    this.description = '',
    this.imageUrl,
    required this.location,
    this.preferredDate,
    this.preferredTime = '',
    required this.status,
    this.statusHistory = const [],
    this.assignedDriver,
    this.createdAt,
    this.updatedAt,
  });

  factory CollectionRequestModel.fromJson(Map<String, dynamic> json) {
    return CollectionRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      requester: json['requester'] is Map<String, dynamic>
          ? RequesterInfo.fromJson(json['requester'])
          : null,
      wasteType: json['wasteType'] ?? '',
      estimatedQuantity: (json['estimatedQuantity'] as num?)?.toDouble() ?? 0,
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      location: json['location'] ?? '',
      preferredDate: json['preferredDate'] != null
          ? DateTime.tryParse(json['preferredDate'])
          : null,
      preferredTime: json['preferredTime'] ?? '',
      status: json['status'] ?? 'requested',
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((h) => StatusHistoryEntry.fromJson(
                    Map<String, dynamic>.from(h),
                  ))
              .toList() ??
          [],
      assignedDriver: json['assignedDriver'] is Map<String, dynamic>
          ? DriverInfo.fromJson(json['assignedDriver'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  /// Human-readable waste type
  String get wasteTypeLabel {
    switch (wasteType) {
      case 'organic':
        return 'Organic';
      case 'plastic':
        return 'Plastic';
      case 'paper':
        return 'Paper';
      case 'glass':
        return 'Glass';
      case 'metal':
        return 'Metal';
      case 'electronic':
        return 'Electronic';
      case 'hazardous':
        return 'Hazardous';
      default:
        return 'Other';
    }
  }

  /// Human-readable status label (capitalize first letter)
  String get statusLabel {
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Color for status badge
  static Color getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return const Color(0xFFFF9800); // Orange
      case 'accepted':
        return const Color(0xFF2196F3); // Blue
      case 'scheduled':
        return const Color(0xFF9C27B0); // Purple
      case 'collected':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  /// Icon for waste type
  static IconData getWasteTypeIcon(String type) {
    switch (type) {
      case 'organic':
        return Icons.eco;
      case 'plastic':
        return Icons.local_drink;
      case 'paper':
        return Icons.description;
      case 'glass':
        return Icons.wine_bar;
      case 'metal':
        return Icons.build;
      case 'electronic':
        return Icons.devices;
      case 'hazardous':
        return Icons.warning_amber;
      default:
        return Icons.delete_outline;
    }
  }
}
