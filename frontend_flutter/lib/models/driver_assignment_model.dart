class AssignmentUserInfo {
  final String id;
  final String name;
  final String? email;

  AssignmentUserInfo({
    required this.id,
    required this.name,
    this.email,
  });

  factory AssignmentUserInfo.fromJson(Map<String, dynamic> json) {
    return AssignmentUserInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
    );
  }
}

class DriverAssignmentModel {
  final String id;
  final String requestId;
  final String driverId;
  final AssignmentUserInfo? assignedBy;
  final DateTime? assignedAt;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DriverAssignmentModel({
    required this.id,
    required this.requestId,
    required this.driverId,
    this.assignedBy,
    this.assignedAt,
    this.status = 'Assigned',
    this.createdAt,
    this.updatedAt,
  });

  factory DriverAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DriverAssignmentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      requestId: json['requestId'] is Map
          ? json['requestId']['_id']?.toString() ?? ''
          : json['requestId']?.toString() ?? '',
      driverId: json['driverId'] is Map
          ? json['driverId']['_id']?.toString() ?? ''
          : json['driverId']?.toString() ?? '',
      assignedBy: json['assignedBy'] is Map<String, dynamic>
          ? AssignmentUserInfo.fromJson(json['assignedBy'])
          : null,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'])
          : null,
      status: json['status'] ?? 'Assigned',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}
