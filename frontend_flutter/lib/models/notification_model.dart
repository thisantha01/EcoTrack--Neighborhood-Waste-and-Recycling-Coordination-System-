class AppNotification {
  final String id;
  final String recipient;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final Map<String, dynamic> metadata;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipient,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.metadata = const {},
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      recipient: json['recipient']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      relatedId: json['relatedId']?.toString(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : {},
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isRequestAccepted => type == 'request_accepted';

  String? get targetRequestId =>
      metadata['requestId']?.toString() ?? relatedId;

  String? get wasteType => metadata['wasteType']?.toString();
  String? get quantity => metadata['quantity']?.toString() ?? metadata['estimatedQuantity']?.toString();
  String? get locationAddress => metadata['location']?.toString();

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
