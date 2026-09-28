import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/community_report_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_report_service.dart';
import 'illegal_dumping_report_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final CommunityReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late CommunityReport _report;
  bool _loading = false;
  bool _wasEdited = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final fresh = await CommunityReportService().getReport(_report.id);
      if (mounted) {
        setState(() => _report = fresh);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IllegalDumpingReportScreen(initialReport: _report),
      ),
    );
    if (updated == true) {
      _wasEdited = true;
      await _reload();
    }
  }

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
    final statusColor = _statusColor(_report.status);
    final currentUserId = context.watch<AuthProvider>().user?.id ?? '';
    final isOwner = currentUserId.isNotEmpty &&
        _report.reporter.id.trim() == currentUserId.trim();
    final canEdit = isOwner && _report.status != 'resolved';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context, _wasEdited);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F8E9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          title: const Text('Report Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _wasEdited),
          ),
          actions: [
            if (canEdit)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _openEdit,
                  icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                          _label(_report.status),
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
            title: _report.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_report.description),
                const SizedBox(height: 12),
                _detailRow(Icons.category_outlined, 'Type', _label(_report.type)),
                const SizedBox(height: 8),
                _detailRow(Icons.location_on_outlined, 'Location', _report.location),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Submitted',
                  DateFormat('MMM d, yyyy · h:mm a').format(_report.createdAt),
                ),
                if (_report.reporter.name.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _detailRow(Icons.person_outline, 'Reported by', _report.reporter.name),
                ],
              ],
            ),
          ),
          if (_report.imageUrl != null && _report.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section(
              title: 'Photo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _report.imageUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Padding(
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
            child: _report.additionalInfo.isEmpty
                ? const Text('No additional information yet.',
                    style: TextStyle(color: Colors.black54))
                : Column(
                    children: _report.additionalInfo.map((info) {
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
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _openEdit,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: const Text(
                'Edit Report',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
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
