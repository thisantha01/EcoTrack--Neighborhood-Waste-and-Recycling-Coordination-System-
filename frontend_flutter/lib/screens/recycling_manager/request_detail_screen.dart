import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/manager_provider.dart';
import '../../models/collection_request_model.dart';
import 'manager_assignment_screen.dart';
import 'manager_request_map_screen.dart';

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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot make call to $phoneNumber')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call error: $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ManagerProvider>().fetchRequestDetail(widget.requestId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRequestDetail) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0097A7)),
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
                        backgroundColor: const Color(0xFF0097A7),
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

          final isSpecial = request.estimatedQuantity >= 10.0 ||
              request.wasteType == 'electronic' ||
              request.wasteType == 'hazardous' ||
              request.wasteType == 'organic';

          final pickupDateStr = request.preferredDate != null
              ? DateFormat('EEEE, MMM d, yyyy').format(request.preferredDate!)
              : 'Date not specified';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Header Card
                _buildHeroHeader(request, isSpecial),
                const SizedBox(height: 16),

                // 2. 4-Stage Status Milestone Timeline (Option 2)
                _buildOption2Timeline(request),
                const SizedBox(height: 16),

                // 3. Requester Information Card
                _buildRequesterCard(request),
                const SizedBox(height: 16),

                // 4. Pickup & Waste Specifications Card
                _buildPickupDetailsCard(request, pickupDateStr, isSpecial),
                const SizedBox(height: 16),

                // 5. Driver & Route Assignment Card
                _buildDriverAssignmentCard(request, provider),
                const SizedBox(height: 16),

                // 6. Status History Card
                if (request.statusHistory.isNotEmpty) ...[
                  _buildStatusHistoryCard(request),
                  const SizedBox(height: 16),
                ],

                // 7. Bottom Action Buttons (Map & Assign)
                _buildBottomActionButtons(request, provider, isSpecial),
              ],
            ),
          );
        },
      ),
    );
  }

  // 1. Hero Header
  Widget _buildHeroHeader(CollectionRequest request, bool isSpecial) {
    final statusColor = CollectionRequest.getStatusColor(request.status);
    final shortId = request.id.length > 8
        ? request.id.substring(request.id.length - 8)
        : request.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0097A7),
            const Color(0xFF00838F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0097A7).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ID #$shortId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      request.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  CollectionRequest.getWasteTypeIcon(request.wasteType),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        'Estimated Quantity: ${request.estimatedQuantity} kg',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isSpecial) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, size: 14, color: Colors.black87),
                  SizedBox(width: 5),
                  Text(
                    'Special Pickup: Excess Waste Volume / Type',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 2. 4-Stage Status Milestone Timeline (Option 2)
  Widget _buildOption2Timeline(CollectionRequest request) {
    if (request.status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Request Cancelled',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'This collection request has been cancelled.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Determine current step (0: Requested, 1: Scheduled, 2: In Progress, 3: Collected)
    int currentStep = 0;
    if (request.status == 'collected') {
      currentStep = 3;
    } else if (request.status == 'scheduled' || request.status == 'accepted') {
      // If driver has an active stop or on route, mark as step 2 (In Progress), else step 1 (Scheduled)
      final hasActiveAssignment = request.assignedDriver != null;
      if (hasActiveAssignment &&
          request.statusHistory.any((h) =>
              h.note.toLowerCase().contains('transit') ||
              h.note.toLowerCase().contains('progress') ||
              h.note.toLowerCase().contains('started'))) {
        currentStep = 2;
      } else {
        currentStep = 1;
      }
    }

    final stages = [
      {
        'title': 'Requested',
        'desc': DateFormat('MMM d, h:mm a').format(request.createdAt),
        'icon': Icons.assignment_outlined,
      },
      {
        'title': 'Scheduled',
        'desc': request.assignedDriver != null
            ? 'Driver: ${request.assignedDriver!.name}'
            : (currentStep >= 1 ? 'Route Assigned' : 'Pending assign'),
        'icon': Icons.calendar_today_outlined,
      },
      {
        'title': 'In Progress',
        'desc': currentStep >= 2
            ? 'Out for collection'
            : (currentStep == 1 ? 'Waiting route start' : 'Pending'),
        'icon': Icons.local_shipping_outlined,
      },
      {
        'title': 'Collected',
        'desc': currentStep == 3 ? 'Completed' : 'Pending arrival',
        'icon': Icons.check_circle_outline,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline, size: 18, color: Color(0xFF0097A7)),
              SizedBox(width: 8),
              Text(
                'Collection Status Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stepper Items
          Column(
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              final isDone = index < currentStep;
              final isCurrent = index == currentStep;
              final isLast = index == stages.length - 1;

              final circleColor = isDone
                  ? Colors.green.shade600
                  : (isCurrent ? const Color(0xFF0097A7) : Colors.grey.shade300);

              final circleIconColor = (isDone || isCurrent)
                  ? Colors.white
                  : Colors.grey.shade600;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column of Circle + Connecting Line
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(
                                    color: const Color(0xFFE0F7FA),
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Icon(
                            isDone ? Icons.check : (stage['icon'] as IconData),
                            size: 14,
                            color: circleIconColor,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.5,
                              color: index < currentStep
                                  ? Colors.green.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: (isCurrent || isDone)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: (isCurrent || isDone)
                                    ? const Color(0xFF263238)
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stage['desc'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: (isCurrent || isDone)
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 3. Requester Information Card
  Widget _buildRequesterCard(CollectionRequest request) {
    final requester = request.requester;
    final name = requester?.name ??
        (request.requesterName.isNotEmpty
            ? request.requesterName
            : 'Unknown Resident');
    final phone = requester?.phone ?? '';
    final email = requester?.email ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resident Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              if (phone.isNotEmpty)
                InkWell(
                  onTap: () => _makePhoneCall(phone),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0097A7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.phone, size: 14, color: Color(0xFF00838F)),
                        SizedBox(width: 4),
                        Text(
                          'Call Resident',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, 'Resident Name', name),
          if (phone.isNotEmpty) _infoRow(Icons.phone_outlined, 'Phone', phone),
          if (email.isNotEmpty) _infoRow(Icons.email_outlined, 'Email', email),
          _infoRow(Icons.location_on_outlined, 'Address', request.location),
        ],
      ),
    );
  }

  // 4. Pickup & Waste Specifications Card
  Widget _buildPickupDetailsCard(
    CollectionRequest request,
    String pickupDateStr,
    bool isSpecial,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup & Waste Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.category_outlined,
            'Waste Category',
            request.wasteTypeLabel,
          ),
          if (request.estimatedQuantity > 0)
            _infoRow(
              Icons.scale_outlined,
              'Estimated Weight',
              '${request.estimatedQuantity} kg',
            ),
          _infoRow(Icons.calendar_today_outlined, 'Pickup Date', pickupDateStr),
          _infoRow(
            Icons.access_time_outlined,
            'Pickup Time Slot',
            (request.preferredTime ?? '').isNotEmpty
                ? request.preferredTime!
                : 'Anytime during pickup day',
          ),
          if (request.description.isNotEmpty)
            _infoRow(
              Icons.notes_outlined,
              'Special Notes',
              request.description,
            ),
          // Waste Photo Thumbnail (if provided)
          if (request.imageUrl != null && request.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Attached Waste Photo',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showFullImage(request.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CachedNetworkImage(
                      imageUrl: request.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        height: 120,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (ctx, url, error) => Container(
                        height: 80,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Tap to Zoom',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 5. Driver Assignment Card
  Widget _buildDriverAssignmentCard(
    CollectionRequest request,
    ManagerProvider provider,
  ) {
    final driver = request.assignedDriver;
    final assignment = provider.selectedRequestAssignment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: driver != null ? Colors.grey.shade200 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned Driver & Vehicle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              if (driver != null && (driver.phone ?? '').isNotEmpty)
                InkWell(
                  onTap: () => _makePhoneCall(driver.phone!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0097A7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.phone, size: 14, color: Color(0xFF00838F)),
                        SizedBox(width: 4),
                        Text(
                          'Call Driver',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (driver != null) ...[
            _infoRow(Icons.person_pin, 'Driver Name', driver.name),
            if ((driver.phone ?? '').isNotEmpty)
              _infoRow(Icons.phone_outlined, 'Driver Phone', driver.phone!),
            if ((driver.vehicleType ?? '').isNotEmpty)
              _infoRow(
                Icons.local_shipping_outlined,
                'Vehicle',
                driver.vehicleType!,
              ),
            if (assignment?.assignedAt != null)
              _infoRow(
                Icons.schedule_outlined,
                'Assigned At',
                DateFormat('MMM d, yyyy • h:mm a').format(assignment!.assignedAt!),
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade800,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'No Driver Assigned Yet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.brown,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Assign this collection request to an active driver and route.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. Status History Card
  Widget _buildStatusHistoryCard(CollectionRequest request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Activity Log',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),
          ...request.statusHistory.reversed.map((entry) {
            final dateStr =
                DateFormat('MMM d, yyyy • h:mm a').format(entry.timestamp);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF0097A7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (entry.note.isNotEmpty)
                          Text(
                            entry.note,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 7. Bottom Action Buttons
  Widget _buildBottomActionButtons(
    CollectionRequest request,
    ManagerProvider provider,
    bool isSpecial,
  ) {
    return Row(
      children: [
        // View on Map Button
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11),
              side: const BorderSide(color: Color(0xFF0097A7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerRequestMapScreen(request: request),
                ),
              );
            },
            icon: const Icon(
              Icons.map_outlined,
              size: 18,
              color: Color(0xFF0097A7),
            ),
            label: const Text(
              'View on Map',
              style: TextStyle(
                color: Color(0xFF0097A7),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Assign / Reassign Driver Button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0097A7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerAssignmentScreen(request: request),
                ),
              ).then((assigned) {
                if (assigned == true && mounted) {
                  provider.fetchRequestDetail(widget.requestId);
                  provider.fetchAvailableDrivers();
                  provider.fetchDashboardStats();
                }
              });
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              request.assignedDriver != null ? 'Reassign Route' : 'Assign Driver',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (ctx, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (ctx, url, error) => Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: const Text('Failed to load image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
