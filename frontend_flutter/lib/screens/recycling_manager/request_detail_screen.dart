import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../providers/manager_provider.dart';
import '../../models/collection_request_model.dart';
import 'assign_driver_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerProvider>().fetchRequestDetail(widget.requestId);
    });
  }

  void _navigateToAssignDriver() {
    final provider = context.read<ManagerProvider>();
    final request = provider.selectedRequest;
    if (request == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignDriverScreen(
          requestId: request.id,
          requestWasteType: request.wasteTypeLabel,
          requestLocation: request.location,
        ),
      ),
    ).then((_) {
      provider.fetchRequestDetail(widget.requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRequestDetail) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
            );
          }

          if (provider.error != null && provider.selectedRequest == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          provider.fetchRequestDetail(widget.requestId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final request = provider.selectedRequest;
          if (request == null) {
            return const Center(child: Text('Request not found'));
          }

          final statusColor = CollectionRequest.getStatusColor(request.status);
          final createdStr = request.createdAt != null
              ? DateFormat('MMM d, yyyy • h:mm a').format(request.createdAt!)
              : 'N/A';
          final pickupDateStr = request.preferredDate != null
              ? DateFormat('EEEE, MMM d, yyyy').format(request.preferredDate!)
              : 'Not set';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Request ID header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Request #${request.id.substring(request.id.length > 8 ? request.id.length - 8 : 0)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.wasteTypeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request.estimatedQuantity > 0)
                        Text(
                          'Est. ${request.estimatedQuantity} kg',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Requester Information
                _sectionTitle('Requester Information'),
                const SizedBox(height: 8),
                _infoCard(
                  children: [
                    _infoRow(
                      Icons.person,
                      'Name',
                      request.requester?.name ?? 'Unknown',
                    ),
                    if (request.requester?.email != null)
                      _infoRow(Icons.email, 'Email', request.requester!.email!),
                    if (request.requester?.phone != null &&
                        request.requester!.phone!.isNotEmpty)
                      _infoRow(Icons.phone, 'Phone', request.requester!.phone!),
                  ],
                ),
                const SizedBox(height: 16),

                // Pickup Details
                _sectionTitle('Pickup Details'),
                const SizedBox(height: 8),
                _infoCard(
                  children: [
                    _infoRow(Icons.location_on, 'Location', request.location),
                    _infoRow(
                      Icons.calendar_today,
                      'Preferred Date',
                      pickupDateStr,
                    ),
                    _infoRow(
                      Icons.access_time,
                      'Preferred Time',
                      (request.preferredTime ?? '').isNotEmpty
                          ? request.preferredTime!
                          : 'Not specified',
                    ),
                    _infoRow(
                      Icons.category,
                      'Waste Type',
                      request.wasteTypeLabel,
                    ),
                    if (request.estimatedQuantity > 0)
                      _infoRow(
                        Icons.scale,
                        'Est. Quantity',
                        '${request.estimatedQuantity} kg',
                      ),
                    if (request.description.isNotEmpty)
                      _infoRow(Icons.notes, 'Description', request.description),
                    if (request.imageUrl != null &&
                        request.imageUrl!.isNotEmpty)
                      _infoRow(
                        Icons.photo,
                        'Waste Photo',
                        'Available',
                        trailing: GestureDetector(
                          onTap: () => _showFullImage(request.imageUrl!),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              color: Color(0xFF6A1B9A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Driver Assignment
                _sectionTitle('Driver Assignment'),
                const SizedBox(height: 8),
                if (request.assignedDriver != null &&
                    provider.selectedRequestAssignment != null)
                  _infoCard(
                    children: [
                      _infoRow(
                        Icons.person,
                        'Driver',
                        request.assignedDriver!.name,
                      ),
                      if (request.assignedDriver!.phone != null)
                        _infoRow(
                          Icons.phone,
                          'Phone',
                          request.assignedDriver!.phone!,
                        ),
                      if (request.assignedDriver!.vehicleType != null)
                        _infoRow(
                          Icons.local_shipping,
                          'Vehicle',
                          request.assignedDriver!.vehicleType!,
                        ),
                      _infoRow(
                        Icons.info_outline,
                        'Assignment Status',
                        provider.selectedRequestAssignment!.status,
                      ),
                      if (provider.selectedRequestAssignment!.assignedBy !=
                          null)
                        _infoRow(
                          Icons.badge,
                          'Assigned By',
                          provider.selectedRequestAssignment!.assignedBy!.name,
                        ),
                      if (provider.selectedRequestAssignment!.assignedAt !=
                          null)
                        _infoRow(
                          Icons.schedule,
                          'Assigned At',
                          DateFormat('MMM d, yyyy • h:mm a').format(
                            provider.selectedRequestAssignment!.assignedAt!,
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 36,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No driver assigned yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assign a driver to handle this collection request',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Status History
                if (request.statusHistory.isNotEmpty) ...[
                  _sectionTitle('Status History'),
                  const SizedBox(height: 8),
                  _infoCard(
                    children: request.statusHistory.map((entry) {
                      return _infoRow(
                        Icons.history,
                        entry.status[0].toUpperCase() +
                            entry.status.substring(1),
                        entry.timestamp != null
                            ? DateFormat(
                                'MMM d, yyyy • h:mm a',
                              ).format(entry.timestamp!)
                            : '',
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Timeline
                _sectionTitle('Timeline'),
                const SizedBox(height: 8),
                _infoCard(
                  children: [
                    _infoRow(Icons.add_circle_outline, 'Created', createdStr),
                    if (request.updatedAt != null)
                      _infoRow(
                        Icons.update,
                        'Last Updated',
                        DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(request.updatedAt!),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                if (request.assignedDriver == null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _navigateToAssignDriver,
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        'Assign Driver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (ctx, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (ctx, url, error) => const Center(
              child: Icon(Icons.error, size: 48, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
