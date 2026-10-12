import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _service.getNotifications();
      setState(() {
        _notifications = res['notifications'] as List<AppNotification>;
        _unreadCount = res['unreadCount'] as int;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final ok = await _service.markAllAsRead();
    if (ok) {
      setState(() {
        for (final n in _notifications) {
          n.isRead = true;
        }
        _unreadCount = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    if (!notification.isRead) {
      _service.markAsRead(notification.id);
      setState(() {
        notification.isRead = true;
        if (_unreadCount > 0) _unreadCount--;
      });
    }

    _showNotificationDetailsModal(notification);
  }

  void _showNotificationDetailsModal(AppNotification n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (n.isRequestScheduled ? const Color(0xFF1565C0) : const Color(0xFF2E7D32)).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    n.isRequestScheduled ? Icons.local_shipping : Icons.check_circle_outline,
                    color: n.isRequestScheduled ? const Color(0xFF1565C0) : const Color(0xFF2E7D32),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        n.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Text(
                n.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirmation Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            if (n.targetRequestId != null)
              _detailRow('Request ID', '#${n.targetRequestId!.substring(n.targetRequestId!.length > 8 ? n.targetRequestId!.length - 8 : 0).toUpperCase()}'),
            if (n.wasteType != null && n.wasteType!.isNotEmpty)
              _detailRow('Waste Category', n.wasteType!),
            if (n.quantity != null && n.quantity!.isNotEmpty)
              _detailRow('Estimated Amount', '${n.quantity} kg'),
            if (n.locationAddress != null && n.locationAddress!.isNotEmpty)
              _detailRow('Pickup Address', n.locationAddress!),
            if (n.driverName != null && n.driverName!.isNotEmpty)
              _detailRow('Assigned Driver', n.driverName!),
            _detailRow(
              'Status',
              n.isRequestScheduled ? 'Scheduled with Driver' : 'Accepted & Confirmed',
              isSuccess: true,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                if (n.targetRequestId != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestDetailScreen(
                              requestId: n.targetRequestId!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSuccess ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                size: 54,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No Notifications Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'When your collection requests are accepted by municipal coordination, you will be notified here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF2E7D32),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return Material(
                            color: n.isRead ? Colors.white : const Color(0xFFF9FBE7),
                            borderRadius: BorderRadius.circular(16),
                            elevation: n.isRead ? 1 : 2,
                            child: InkWell(
                              onTap: () => _handleNotificationTap(n),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: n.isRead
                                        ? Colors.grey.shade200
                                        : const Color(0xFFC8E6C9),
                                    width: n.isRead ? 1 : 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: n.isRequestScheduled
                                            ? const Color(0xFF1565C0).withAlpha(25)
                                            : (n.isRequestAccepted
                                                ? const Color(0xFF2E7D32).withAlpha(25)
                                                : const Color(0xFF1565C0).withAlpha(25)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        n.isRequestScheduled
                                            ? Icons.local_shipping
                                            : (n.isRequestAccepted
                                                ? Icons.check_circle
                                                : Icons.notifications),
                                        color: n.isRequestScheduled
                                            ? const Color(0xFF1565C0)
                                            : (n.isRequestAccepted
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFF1565C0)),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n.title,
                                                  style: TextStyle(
                                                    fontWeight: n.isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                n.timeAgo,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            n.message,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                'Tap to view confirmation details',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF2E7D32),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.chevron_right,
                                                size: 14,
                                                color: Color(0xFF2E7D32),
                                              ),
                                              const Spacer(),
                                              if (!n.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF2E7D32),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
