import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/collection_request_model.dart';
import '../../services/collection_request_service.dart';
import 'request_collection_screen.dart';
import 'request_detail_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  List<CollectionRequest> _requests = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await CollectionRequestService.getMyRequests();
      setState(() => _requests = requests);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<CollectionRequest> _byStatus(String status) =>
      _requests.where((r) => r.status == status).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('🗑️ Collection Requests',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(text: 'Requested (${_byStatus('requested').length})'),
            Tab(text: 'Accepted (${_byStatus('accepted').length})'),
            Tab(text: 'Scheduled (${_byStatus('scheduled').length})'),
            Tab(text: 'Collected (${_byStatus('collected').length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestCollectionScreen()),
          );
          if (result == true) _load();
        },
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_byStatus('requested')),
                    _buildList(_byStatus('accepted')),
                    _buildList(_byStatus('scheduled')),
                    _buildList(_byStatus('collected')),
                  ],
                ),
    );
  }

  Widget _buildList(List<CollectionRequest> requests) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No requests here',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (ctx, i) => _RequestCard(
          request: requests[i],
          statusColor: _statusColor(requests[i].status),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestDetailScreen(requestId: requests[i].id),
              ),
            );
            if (result == true) _load();
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CollectionRequest request;
  final Color statusColor;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      request.statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.wasteTypeLabel,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d').format(request.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(request.location,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.scale, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${request.estimatedQuantity} kg',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                  const Spacer(),
                  if (request.preferredDate != null) ...[
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        DateFormat('MMM d, yyyy')
                            .format(request.preferredDate!),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
              if (request.assignedDriverName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('Driver: ${request.assignedDriverName}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Mini status timeline dots
              Row(
                children: ['requested', 'accepted', 'scheduled', 'collected']
                    .map((s) {
                  final isDone = request.statusHistory
                      .any((h) => h.status == s);
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                          ),
                        ),
                        if (s != 'collected')
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isDone
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey.shade300,
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
      ),
    );
  }
}
