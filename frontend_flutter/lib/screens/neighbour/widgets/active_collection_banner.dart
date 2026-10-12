import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/collection_request_model.dart';
import '../../../services/collection_request_service.dart';
import '../../community/request_detail_screen.dart';

/// A dashboard alert banner displayed on the Home tab when the user has an active
/// collection request that has been accepted or scheduled with a driver.
class ActiveCollectionBanner extends StatefulWidget {
  final VoidCallback? onTabSwitchToRequests;

  const ActiveCollectionBanner({super.key, this.onTabSwitchToRequests});

  @override
  State<ActiveCollectionBanner> createState() => _ActiveCollectionBannerState();
}

class _ActiveCollectionBannerState extends State<ActiveCollectionBanner> {
  CollectionRequest? _activeRequest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveRequest();
  }

  Future<void> _loadActiveRequest() async {
    try {
      final requests = await CollectionRequestService.getMyRequests();
      // Look for scheduled requests first, then accepted
      final scheduled = requests.where((r) => r.status == 'scheduled').toList();
      final accepted = requests.where((r) => r.status == 'accepted').toList();

      CollectionRequest? target;
      if (scheduled.isNotEmpty) {
        target = scheduled.first;
      } else if (accepted.isNotEmpty) {
        target = accepted.first;
      }

      if (mounted) {
        setState(() {
          _activeRequest = target;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _activeRequest == null) {
      return const SizedBox.shrink();
    }

    final req = _activeRequest!;
    final isScheduled = req.status == 'scheduled';
    final primaryColor = isScheduled ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final bgColor = isScheduled ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);
    final borderColor = isScheduled ? const Color(0xFF90CAF9) : const Color(0xFFA5D6A7);

    final driverName = req.assignedDriverName ?? req.assignedDriver?.name;
    final dateStr = req.preferredDate != null
        ? DateFormat('MMM d').format(req.preferredDate!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailScreen(requestId: req.id),
              ),
            );
            _loadActiveRequest();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isScheduled ? Icons.local_shipping : Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isScheduled
                                ? 'Pickup Scheduled! 🚚'
                                : 'Request Confirmed! ✅',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (driverName != null && driverName.isNotEmpty)
                            Text(
                              'Driver assigned: $driverName',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.statusLabel.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.recycling, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${req.wasteTypeLabel} • ${req.estimatedQuantity} kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dateStr != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to view tracking & details',
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
