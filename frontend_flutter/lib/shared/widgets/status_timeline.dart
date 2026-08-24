import 'package:flutter/material.dart';
import '../../models/collection_request_model.dart';

class StatusTimeline extends StatelessWidget {
  final List<StatusEntry> statusHistory;
  final List<String> allStatuses;
  final String currentStatus;

  const StatusTimeline({
    super.key,
    required this.statusHistory,
    required this.allStatuses,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final completedStatuses = statusHistory.map((e) => e.status).toSet();

    return Row(
      children: List.generate(allStatuses.length * 2 - 1, (index) {
        // Even indices = dots, odd indices = lines
        if (index.isOdd) {
          final leftStatus = allStatuses[(index - 1) ~/ 2];
          final rightStatus = allStatuses[(index + 1) ~/ 2];
          final leftDone = completedStatuses.contains(leftStatus);
          final rightDone = completedStatuses.contains(rightStatus);

          return Expanded(
            child: Container(
              height: 2,
              color: leftDone && rightDone
                  ? const Color(0xFF2E7D32)
                  : Colors.grey.shade300,
            ),
          );
        }

        final statusIndex = index ~/ 2;
        final status = allStatuses[statusIndex];
        final isCompleted = completedStatuses.contains(status);
        final isCurrent = status == currentStatus;
        final isCancelled = currentStatus == 'cancelled';

        Color dotColor;
        if (isCancelled && !isCompleted) {
          dotColor = Colors.grey;
        } else if (isCurrent) {
          dotColor = const Color(0xFF2E7D32);
        } else if (isCompleted) {
          dotColor = const Color(0xFF2E7D32);
        } else {
          dotColor = Colors.grey.shade300;
        }

        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                border: isCurrent
                    ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                    : null,
              ),
              child: isCompleted || isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              _statusLabel(status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent
                    ? const Color(0xFF2E7D32)
                    : isCompleted
                        ? Colors.black87
                        : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }

  String _statusLabel(String status) {
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
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }
}

// ─── Convenience wrapper for Collection Request status ───

class CollectionRequestTimeline extends StatelessWidget {
  final CollectionRequest request;

  const CollectionRequestTimeline({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return StatusTimeline(
      statusHistory: request.statusHistory,
      allStatuses: const ['requested', 'accepted', 'scheduled', 'collected'],
      currentStatus: request.status,
    );
  }
}

// ─── Convenience wrapper for Report status ───

class ReportTimeline extends StatelessWidget {
  final String currentStatus;
  final List<StatusEntry> statusHistory;

  const ReportTimeline({
    super.key,
    required this.currentStatus,
    required this.statusHistory,
  });

  @override
  Widget build(BuildContext context) {
    return StatusTimeline(
      statusHistory: statusHistory,
      allStatuses: const ['open', 'in_progress', 'resolved'],
      currentStatus: currentStatus,
    );
  }
}
