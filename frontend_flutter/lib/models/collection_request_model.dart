import 'package:flutter/material.dart';

class RequestUser {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profilePicture;
  final String? vehicleType;

  const RequestUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profilePicture,
    this.vehicleType,
  });

  factory RequestUser.fromJson(Map<String, dynamic> json) => RequestUser(
    id: json['_id'] ?? json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'],
    phone: json['phone'],
    profilePicture: json['profilePicture'],
    vehicleType: json['vehicleType'],
  );
}

class StatusEntry {
  final String status;
  final DateTime timestamp;
  final String note;

  StatusEntry({required this.status, required this.timestamp, this.note = ''});

  factory StatusEntry.fromJson(Map<String, dynamic> json) {
    return StatusEntry(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'] ?? '',
    );
  }
}

class CollectionRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterPicture;
  final RequestUser? requester;
  final String wasteType;
  final double estimatedQuantity;
  final String description;
  final String? imageUrl;
  final String location;
  final double? lat;
  final double? lng;
  final DateTime? preferredDate;
  final String? preferredTime;
  final String status;
  final List<StatusEntry> statusHistory;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final RequestUser? assignedDriver;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CollectionRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPicture,
    this.requester,
    required this.wasteType,
    required this.estimatedQuantity,
    this.description = '',
    this.imageUrl,
    required this.location,
    this.lat,
    this.lng,
    this.preferredDate,
    this.preferredTime,
    required this.status,
    this.statusHistory = const [],
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriver,
    required this.createdAt,
    this.updatedAt,
  });

  factory CollectionRequest.fromJson(Map<String, dynamic> json) {
    final requesterJson = json['requester'];
    final assignedDriverJson = json['assignedDriver'];
    final requester = requesterJson is Map
        ? RequestUser.fromJson(Map<String, dynamic>.from(requesterJson))
        : null;
    final assignedDriver = assignedDriverJson is Map
        ? RequestUser.fromJson(Map<String, dynamic>.from(assignedDriverJson))
        : null;

    return CollectionRequest(
      id: json['_id'] ?? json['id'] ?? '',
      requesterId: requester?.id ?? '',
      requesterName: requester?.name ?? '',
      requesterPicture: requester?.profilePicture,
      requester: requester,
      wasteType: json['wasteType'] ?? '',
      estimatedQuantity: (json['estimatedQuantity'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      location: json['location'] ?? '',
      lat: json['coordinates']?['lat']?.toDouble(),
      lng: json['coordinates']?['lng']?.toDouble(),
      preferredDate: json['preferredDate'] != null
          ? DateTime.tryParse(json['preferredDate'])
          : null,
      preferredTime: json['preferredTime'],
      status: json['status'] ?? 'requested',
      statusHistory:
          (json['statusHistory'] as List<dynamic>?)
              ?.map((e) => StatusEntry.fromJson(e))
              .toList() ??
          [],
      assignedDriverId: assignedDriver?.id,
      assignedDriverName: assignedDriver?.name,
      assignedDriver: assignedDriver,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

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

  String get statusLabel {
    switch (status) {
      case 'requested':
        return 'Requested';
      case 'accepted':
        return 'Accepted';
      case 'scheduled':
        return 'Scheduled';
      case 'collected':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'scheduled':
        return Colors.deepPurple;
      case 'collected':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getWasteTypeIcon(String wasteType) {
    switch (wasteType) {
      case 'organic':
        return Icons.compost;
      case 'plastic':
        return Icons.local_drink;
      case 'paper':
        return Icons.description_outlined;
      case 'glass':
        return Icons.wine_bar_outlined;
      case 'metal':
        return Icons.hardware;
      case 'electronic':
        return Icons.devices_other;
      case 'hazardous':
        return Icons.warning_amber_rounded;
      default:
        return Icons.delete_outline;
    }
  }
}
