import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/manager_provider.dart';
import '../../models/collection_request_model.dart';
import 'request_detail_screen.dart';

class CollectionRequestsScreen extends StatefulWidget {
  const CollectionRequestsScreen({super.key});

  @override
  State<CollectionRequestsScreen> createState() =>
      _CollectionRequestsScreenState();
}

class _CollectionRequestsScreenState extends State<CollectionRequestsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerProvider>().fetchCollectionRequests(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ManagerProvider>();
      if (provider.hasMore && !provider.isLoadingRequests) {
        provider.fetchCollectionRequests();
      }
    }
  }

  void _showFilterSheet() {
    final provider = context.read<ManagerProvider>();

    String? tempStatus = provider.filterStatus;
    String? tempWasteType = provider.filterWasteType;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        label: 'All',
                        selected: tempStatus == null,
                        onTap: () => setModalState(() => tempStatus = null),
                      ),
                      _filterChip(
                        label: 'Requested',
                        selected: tempStatus == 'requested',
                        onTap: () =>
                            setModalState(() => tempStatus = 'requested'),
                      ),
                      _filterChip(
                        label: 'Accepted',
                        selected: tempStatus == 'accepted',
                        onTap: () =>
                            setModalState(() => tempStatus = 'accepted'),
                      ),
                      _filterChip(
                        label: 'Scheduled',
                        selected: tempStatus == 'scheduled',
                        onTap: () =>
                            setModalState(() => tempStatus = 'scheduled'),
                      ),
                      _filterChip(
                        label: 'Collected',
                        selected: tempStatus == 'collected',
                        onTap: () =>
                            setModalState(() => tempStatus = 'collected'),
                      ),
                      _filterChip(
                        label: 'Cancelled',
                        selected: tempStatus == 'cancelled',
                        onTap: () =>
                            setModalState(() => tempStatus = 'cancelled'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Waste Type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        label: 'All',
                        selected: tempWasteType == null,
                        onTap: () => setModalState(() => tempWasteType = null),
                      ),
                      _filterChip(
                        label: 'Organic',
                        selected: tempWasteType == 'organic',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'organic'),
                      ),
                      _filterChip(
                        label: 'Plastic',
                        selected: tempWasteType == 'plastic',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'plastic'),
                      ),
                      _filterChip(
                        label: 'Paper',
                        selected: tempWasteType == 'paper',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'paper'),
                      ),
                      _filterChip(
                        label: 'Glass',
                        selected: tempWasteType == 'glass',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'glass'),
                      ),
                      _filterChip(
                        label: 'Metal',
                        selected: tempWasteType == 'metal',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'metal'),
                      ),
                      _filterChip(
                        label: 'Electronic',
                        selected: tempWasteType == 'electronic',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'electronic'),
                      ),
                      _filterChip(
                        label: 'Hazardous',
                        selected: tempWasteType == 'hazardous',
                        onTap: () =>
                            setModalState(() => tempWasteType = 'hazardous'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.clearFilters();
                            provider.fetchCollectionRequests(refresh: true);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            provider.setFilter(
                              status: tempStatus,
                              wasteType: tempWasteType,
                            );
                            provider.fetchCollectionRequests(refresh: true);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6A1B9A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF6A1B9A) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
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
          'Collection Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ManagerProvider>().fetchCollectionRequests(
                refresh: true,
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRequests && provider.requests.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
            );
          }

          if (provider.error != null && provider.requests.isEmpty) {
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
                          provider.fetchCollectionRequests(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No collection requests found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.hasActiveFilters
                        ? 'Try adjusting your filters'
                        : 'Requests will appear here when customers submit them',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (provider.hasActiveFilters)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFF6A1B9A).withOpacity(0.08),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        size: 16,
                        color: Color(0xFF6A1B9A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildFilterLabel(provider),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          provider.clearFilters();
                          provider.fetchCollectionRequests(refresh: true);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${provider.totalRequests} request${provider.totalRequests != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      provider.fetchCollectionRequests(refresh: true),
                  color: const Color(0xFF6A1B9A),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        provider.requests.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.requests.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        );
                      }
                      return _requestCard(provider.requests[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _buildFilterLabel(ManagerProvider provider) {
    final parts = <String>[];
    if (provider.filterStatus != null) {
      parts.add('Status: ${provider.filterStatus}');
    }
    if (provider.filterWasteType != null) {
      parts.add('Type: ${provider.filterWasteType}');
    }
    if (provider.filterDate != null) {
      parts.add('Date: ${provider.filterDate}');
    }
    return 'Filters: ${parts.join(' • ')}';
  }

  Widget _requestCard(CollectionRequest request) {
    final statusColor = CollectionRequest.getStatusColor(request.status);
    final dateStr = request.preferredDate != null
        ? DateFormat('MMM d, yyyy').format(request.preferredDate!)
        : 'Not set';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(requestId: request.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(
                          CollectionRequest.getWasteTypeIcon(request.wasteType),
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.requester?.name ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              request.wasteTypeLabel,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                _detailChip(
                  Icons.location_on_outlined,
                  request.location,
                  flex: true,
                ),
                const SizedBox(width: 8),
                _detailChip(Icons.calendar_today, dateStr),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.assignedDriver != null
                          ? request.assignedDriver!.name
                          : 'No driver assigned',
                      style: TextStyle(
                        fontSize: 11,
                        color: request.assignedDriver != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (request.estimatedQuantity > 0)
                  Text(
                    '${request.estimatedQuantity} kg',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text, {bool flex = false}) {
    return Expanded(
      flex: flex ? 1 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
