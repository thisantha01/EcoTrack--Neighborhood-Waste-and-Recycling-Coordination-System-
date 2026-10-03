import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/collection_request_model.dart';
import '../../services/collection_request_service.dart';
import '../../shared/widgets/status_timeline.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  CollectionRequest? _request;
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
      final request =
          await CollectionRequestService.getRequest(widget.requestId);
      setState(() => _request = request);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'requested':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'scheduled':
        return Colors.purple;
      case 'collected':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CollectionRequestService.cancelRequest(widget.requestId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Request Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
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
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final request = _request!;
    final color = _statusColor(request.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Column(
              children: [
                Icon(
                  request.status == 'collected'
                      ? Icons.check_circle
                      : request.status == 'cancelled'
                          ? Icons.cancel
                          : (request.status == 'scheduled'
                              ? Icons.local_shipping
                              : Icons.hourglass_top),
                  color: color,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  request.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Status timeline
          const Text('Status Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CollectionRequestTimeline(request: request),
          ),

          const SizedBox(height: 20),

          // Request info
          const Text('Request Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _wasteTypeRow(request),
                const Divider(),
                _infoRow(Icons.scale, 'Quantity',
                    '${request.estimatedQuantity} kg'),
                const Divider(),
                _infoRow(Icons.location_on, 'Location', request.location),
                const Divider(),
                if (request.preferredDate != null)
                  _infoRow(
                      Icons.calendar_today,
                      'Preferred Date',
                      DateFormat('MMM d, yyyy')
                          .format(request.preferredDate!)),
                if (request.preferredDate != null) const Divider(),
                if (request.preferredTime != null)
                  _infoRow(Icons.access_time, 'Preferred Time',
                      request.preferredTime!),
                if (request.preferredTime != null) const Divider(),
                _infoRow(Icons.person, 'Requested By', request.requesterName),
                if (request.assignedDriverName != null) ...[
                  const Divider(),
                  _infoRow(Icons.local_shipping, 'Assigned Driver',
                      request.assignedDriverName!),
                ],
              ],
            ),
          ),

          // Photo (if uploaded)
          if (request.imageUrl != null) ...[
            const SizedBox(height: 20),
            const Text('Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(request.imageUrl!),
            ),
          ],

          // Description
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(request.description,
                  style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ],

          // Status history log
          if (request.statusHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: request.statusHistory.reversed.map((entry) {
                  final entryColor = _statusColor(entry.status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.status[0].toUpperCase() +
                                    entry.status.substring(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: entryColor,
                                ),
                              ),
                              if (entry.note.isNotEmpty)
                                Text(entry.note,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a')
                                    .format(entry.timestamp.toLocal()),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
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

          // Cancel button
          if (request.status == 'requested' ||
              request.status == 'accepted') ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelRequest,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text('Cancel Request',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _wasteTypeRow(CollectionRequest request) {
    final types = request.wasteTypes.isNotEmpty
        ? request.wasteTypes
        : (request.wasteType.isNotEmpty ? [request.wasteType] : ['other']);
    final isMultiple = types.length > 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.category, size: 18, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMultiple ? 'Waste Types' : 'Waste Type',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: types.map((type) {
                  final label = CollectionRequest.formatWasteType(type);
                  final icon = CollectionRequest.getWasteTypeIcon(type);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: const Color(0xFF2E7D32)),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('data:image') || url.startsWith('base64,')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str.trim());
        return Image.memory(
          bytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
        );
      } catch (_) {
        return _imagePlaceholder();
      }
    }
    return Image.network(
      url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
