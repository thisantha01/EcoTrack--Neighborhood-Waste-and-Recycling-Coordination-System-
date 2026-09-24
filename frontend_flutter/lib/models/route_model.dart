class RouteStop {
  final String? collectionRequestId;
  final double lat;
  final double lng;
  final String address;
  final int sequenceOrder;
  final String status;

  RouteStop({
    this.collectionRequestId,
    required this.lat,
    required this.lng,
    required this.address,
    required this.sequenceOrder,
    this.status = 'pending',
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final latVal = loc['lat'] ?? json['lat'] ?? 0.0;
    final lngVal = loc['lng'] ?? json['lng'] ?? 0.0;

    String? reqId;
    if (json['collectionRequestId'] != null) {
      if (json['collectionRequestId'] is Map) {
        reqId = (json['collectionRequestId'] as Map)['_id']?.toString();
      } else {
        reqId = json['collectionRequestId'].toString();
      }
    }

    return RouteStop(
      collectionRequestId: reqId,
      lat: (latVal is num) ? latVal.toDouble() : 0.0,
      lng: (lngVal is num) ? lngVal.toDouble() : 0.0,
      address: json['address']?.toString() ?? '',
      sequenceOrder: (json['sequenceOrder'] is num)
          ? (json['sequenceOrder'] as num).toInt()
          : 1,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        if (collectionRequestId != null)
          'collectionRequestId': collectionRequestId,
        'location': {'lat': lat, 'lng': lng},
        'address': address,
        'sequenceOrder': sequenceOrder,
        'status': status,
      };

  RouteStop copyWith({
    String? collectionRequestId,
    double? lat,
    double? lng,
    String? address,
    int? sequenceOrder,
    String? status,
  }) {
    return RouteStop(
      collectionRequestId: collectionRequestId ?? this.collectionRequestId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      status: status ?? this.status,
    );
  }

  bool get isSpecialRequest => collectionRequestId != null && collectionRequestId!.isNotEmpty;
  bool get isCollected => status.toLowerCase() == 'collected';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isSkipped => status.toLowerCase() == 'skipped';
}

class WeeklyScheduleItem {
  final String day;
  final String category;

  WeeklyScheduleItem({required this.day, required this.category});

  factory WeeklyScheduleItem.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItem(
      day: json['day']?.toString() ?? '',
      category: json['category']?.toString() ?? 'organic',
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'category': category,
      };
}

class RouteModel {
  final String id;
  final String routeName;
  final String zone;
  final String description;
  final List<String> assignedLocations;
  final double? areaLat;
  final double? areaLng;
  final List<String> operatingDays;
  final String targetWasteType;
  final List<WeeklyScheduleItem> weeklyCategorySchedule;
  final DateTime? date;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final String? assignedDriverVehicle;
  final List<RouteStop> routeStops;
  final String status;
  final String routeStatus;
  final int activeStopCount;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.zone,
    this.description = '',
    this.assignedLocations = const [],
    this.areaLat,
    this.areaLng,
    this.operatingDays = const [],
    this.targetWasteType = 'weekly_schedule',
    this.weeklyCategorySchedule = const [],
    this.date,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.assignedDriverVehicle,
    this.routeStops = const [],
    this.status = 'Active',
    this.routeStatus = 'Active',
    this.activeStopCount = 0,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final driver = json['assignedDriver'];
    String? driverId;
    String? driverName;
    String? driverPhone;
    String? driverVehicle;

    if (driver is Map) {
      driverId = driver['_id']?.toString() ?? driver['driverId']?.toString();
      driverName = driver['name']?.toString();
      driverPhone = driver['phone']?.toString();
      driverVehicle = driver['vehicleType']?.toString();
    } else if (driver != null) {
      driverId = driver.toString();
    }

    final coords = json['areaCoordinates'] as Map<String, dynamic>? ?? {};
    final areaLat = (coords['lat'] is num) ? (coords['lat'] as num).toDouble() : null;
    final areaLng = (coords['lng'] is num) ? (coords['lng'] as num).toDouble() : null;

    final rawStops = (json['routeStops'] as List?) ?? (json['stops'] as List?) ?? [];
    final routeStops = rawStops
        .whereType<Map>()
        .map((s) => RouteStop.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    routeStops.sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    final pendingCount = routeStops.where((s) => s.status == 'pending').length;

    return RouteModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? 'Route',
      zone: json['zone']?.toString() ?? 'Malabe',
      description: json['description']?.toString() ?? '',
      assignedLocations: (json['assignedLocations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      areaLat: areaLat,
      areaLng: areaLng,
      operatingDays: (json['operatingDays'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      targetWasteType: json['targetWasteType']?.toString() ?? 'weekly_schedule',
      weeklyCategorySchedule: (json['weeklyCategorySchedule'] as List?)
              ?.whereType<Map>()
              .map((s) => WeeklyScheduleItem.fromJson(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      assignedDriverId: driverId,
      assignedDriverName: driverName,
      assignedDriverPhone: driverPhone,
      assignedDriverVehicle: driverVehicle,
      routeStops: routeStops,
      status: json['status']?.toString() ?? 'Active',
      routeStatus: json['routeStatus']?.toString() ?? 'Active',
      activeStopCount: (json['activeStopCount'] is num)
          ? (json['activeStopCount'] as num).toInt()
          : pendingCount,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'routeName': routeName,
        'zone': zone,
        'description': description,
        'assignedLocations': assignedLocations,
        'areaCoordinates': {'lat': areaLat, 'lng': areaLng},
        'operatingDays': operatingDays,
        'targetWasteType': targetWasteType,
        'weeklyCategorySchedule': weeklyCategorySchedule.map((s) => s.toJson()).toList(),
        'date': date?.toIso8601String(),
        'assignedDriver': assignedDriverId,
        'routeStops': routeStops.map((s) => s.toJson()).toList(),
        'status': status,
        'routeStatus': routeStatus,
      };

  String getTodayCategory() {
    if (targetWasteType != 'weekly_schedule' && targetWasteType.isNotEmpty) {
      return targetWasteType;
    }
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final today = days[DateTime.now().weekday - 1];
    String cat = 'organic';
    final match = weeklyCategorySchedule.where((s) => s.day == today);
    if (match.isNotEmpty) {
      cat = match.first.category;
      if ((today == 'Tuesday' || today == 'Thursday') && (cat == 'plastic_paper' || cat == 'plastic' || cat == 'paper')) {
        cat = 'special_requests';
      } else if (today == 'Wednesday' && cat == 'organic') {
        cat = 'plastic_paper';
      } else if (today == 'Friday' && cat == 'organic') {
        cat = 'glass_others';
      }
    } else {
      switch (today) {
        case 'Tuesday':
        case 'Thursday':
          cat = 'special_requests';
          break;
        case 'Wednesday':
          cat = 'plastic_paper';
          break;
        case 'Friday':
          cat = 'glass_others';
          break;
        case 'Saturday':
          cat = 'special_requests';
          break;
        default:
          cat = 'organic';
          break;
      }
    }

    if (cat == 'plastic' || cat == 'paper') return 'plastic_paper';
    if (cat == 'glass_metal' || cat == 'glass' || cat == 'other') return 'glass_others';
    return cat;
  }

  bool get isActive =>
      status == 'Active' || status == 'assigned' || status == 'in-progress';
}

