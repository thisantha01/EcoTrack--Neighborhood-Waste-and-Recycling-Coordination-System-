import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/community_report_model.dart';

class ReportDetailScreen extends StatelessWidget {
  final CommunityReport report;

  const ReportDetailScreen({super.key, required this.report});

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color(0xFF2E7D32);
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _label(String value) => value
      .split('_')
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Report Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(24),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withAlpha(90)),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, color: statusColor, size: 30),
                const SizedBox(width: 12),
                Text(
                  _label(report.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            title: report.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.description),
                const SizedBox(height: 12),
                _detailRow(Icons.category_outlined, 'Type', _label(report.type)),
                const SizedBox(height: 8),
                _detailRow(Icons.location_on_outlined, 'Location', report.location),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Submitted',
                  DateFormat('MMM d, yyyy · h:mm a').format(report.createdAt),
                ),
                if (report.reporter.name.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _detailRow(Icons.person_outline, 'Reported by', report.reporter.name),
                ],
              ],
            ),
          ),
          if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section(
              title: 'Photo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  report.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Unable to load this photo.'),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _section(
            title: 'Community updates',
            child: report.additionalInfo.isEmpty
                ? const Text('No additional information yet.',
                    style: TextStyle(color: Colors.black54))
                : Column(
                    children: report.additionalInfo.map((info) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.comment_outlined,
                                color: Color(0xFF2E7D32)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(info.text.isEmpty ? 'Photo update' : info.text),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${info.user.name} · ${DateFormat('MMM d, yyyy').format(info.createdAt)}',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 12),
                                  ),
                                  if (info.imageUrl != null && info.imageUrl!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        info.imageUrl!,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text('$label: $value')),
      ],
    );
  }
}
