class StatusEntry {
  final String status;
  final DateTime timestamp;
  final String note;

  StatusEntry({
    required this.status,
    required this.timestamp,
    this.note = '',
  });

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
  final DateTime createdAt;

  CollectionRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPicture,
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
    required this.createdAt,
  });

  factory CollectionRequest.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'];
    final assignedDriver = json['assignedDriver'];

    return CollectionRequest(
      id: json['_id'] ?? json['id'] ?? '',
      requesterId: requester is Map ? requester['_id'] ?? '' : '',
      requesterName: requester is Map ? requester['name'] ?? '' : '',
      requesterPicture: requester is Map ? requester['profilePicture'] : null,
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
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((e) => StatusEntry.fromJson(e))
              .toList() ??
          [],
      assignedDriverId: assignedDriver is Map ? assignedDriver['_id'] : null,
      assignedDriverName: assignedDriver is Map ? assignedDriver['name'] : null,
      createdAt: DateTime.parse(json['createdAt']),
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
}
