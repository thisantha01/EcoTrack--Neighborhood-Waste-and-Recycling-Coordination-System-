class PickupModel {
  final String id;
  final String pickupNumber;
  final String customerName;
  final String? customerPhone;
  final String address;
  final String wasteType;
  final double weightKg;
  final String scheduledTime;
  final String status; // 'completed', 'accepted', 'scheduled'
  final String? notes;

  PickupModel({
    required this.id,
    required this.pickupNumber,
    required this.customerName,
    this.customerPhone,
    required this.address,
    required this.wasteType,
    required this.weightKg,
    required this.scheduledTime,
    required this.status,
    this.notes,
  });

  factory PickupModel.fromJson(Map<String, dynamic> json) {
    return PickupModel(
      id: json['_id'] ?? json['id'] ?? '',
      pickupNumber: json['pickupNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      address: json['address'] ?? '',
      wasteType: json['wasteType'] ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      scheduledTime: json['scheduledTime'] ?? '',
      status: (json['status'] as String?)?.toLowerCase() ?? 'scheduled',
      notes: json['notes'],
    );
  }

  PickupModel copyWith({String? status}) {
    return PickupModel(
      id: id,
      pickupNumber: pickupNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      wasteType: wasteType,
      weightKg: weightKg,
      scheduledTime: scheduledTime,
      status: status ?? this.status,
      notes: notes,
    );
  }
}
