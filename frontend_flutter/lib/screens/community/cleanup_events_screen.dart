import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/cleanup_event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/cleanup_event_service.dart';

class CleanupEventsScreen extends StatefulWidget {
  const CleanupEventsScreen({super.key});

  @override
  State<CleanupEventsScreen> createState() => _CleanupEventsScreenState();
}

class _CleanupEventsScreenState extends State<CleanupEventsScreen>
    with SingleTickerProviderStateMixin {
  final CleanupEventService _service = CleanupEventService();
  List<CleanupEvent> _events = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _service.getEvents();
      setState(() => _events = events);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<CleanupEvent> _getEventsByStatus(String status) {
    return _events.where((e) => e.status == status).toList();
  }

  Future<void> _showCreateEventDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime? selectedDate;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌱 Create Cleanup Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.calendar_today,
                      color: Color(0xFF2E7D32)),
                  title: Text(
                    selectedDate != null
                        ? DateFormat('MMM d, yyyy – hh:mm a')
                            .format(selectedDate!)
                        : 'Select Date & Time',
                    style: TextStyle(
                      color: selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate:
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time == null) return;
                    setModal(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty ||
                          locationCtrl.text.trim().isEmpty ||
                          selectedDate == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all required fields')),
                        );
                        return;
                      }
                      try {
                        await _service.createEvent(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          scheduledAt: selectedDate!,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                              content: Text(e
                                  .toString()
                                  .replaceFirst('Exception: ', ''))));
                        }
                      }
                    },
                    child: const Text('Create Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true) _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('🌿 Cleanup Events',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
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
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadEvents, child: const Text('Retry')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(
                        _getEventsByStatus('upcoming'), currentUserId),
                    _buildEventList(
                        _getEventsByStatus('ongoing'), currentUserId),
                    _buildEventList(
                        _getEventsByStatus('completed'), currentUserId),
                  ],
                ),
    );
  }

  Widget _buildEventList(List<CleanupEvent> events, String currentUserId) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cleaning_services, size: 64, color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text('No events here yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: events.length,
        itemBuilder: (ctx, i) => _EventCard(
          event: events[i],
          currentUserId: currentUserId,
          onJoin: () async {
            try {
              await _service.toggleJoin(events[i].id);
              _loadEvents();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', ''))));
              }
            }
          },
          onUpdateStatus: events[i].organizer.id == currentUserId
              ? () => _showUpdateStatusDialog(events[i])
              : null,
        ),
      ),
    );
  }

  Future<void> _showUpdateStatusDialog(CleanupEvent event) async {
    String selectedStatus = event.status;
    final wasteCtrl = TextEditingController(
        text: event.wasteCollected > 0 ? event.wasteCollected.toString() : '');
    final recycledCtrl = TextEditingController(
        text: event.wasteRecycled > 0 ? event.wasteRecycled.toString() : '');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Update Event Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration:
                    const InputDecoration(labelText: 'Status'),
                items: ['upcoming', 'ongoing', 'completed', 'cancelled']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) => setDialog(() => selectedStatus = v!),
              ),
              if (selectedStatus == 'completed') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: wasteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Waste Collected (kg)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: recycledCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Waste Recycled (kg)'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  await _service.updateStatus(
                    event.id,
                    selectedStatus,
                    wasteCollected: double.tryParse(wasteCtrl.text),
                    wasteRecycled: double.tryParse(recycledCtrl.text),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadEvents();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content:
                            Text(e.toString().replaceFirst('Exception: ', ''))));
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CleanupEvent event;
  final String currentUserId;
  final VoidCallback onJoin;
  final VoidCallback? onUpdateStatus;

  const _EventCard({
    required this.event,
    required this.currentUserId,
    required this.onJoin,
    this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isParticipant =
        event.participants.any((p) => p.id == currentUserId);
    final statusColor = {
          'upcoming': const Color(0xFF1976D2),
          'ongoing': const Color(0xFF388E3C),
          'completed': Colors.grey,
          'cancelled': Colors.red,
        }[event.status] ??
        Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    event.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(event.description,
                  style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            _infoRow(Icons.location_on, event.location),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_today,
                DateFormat('MMM d, yyyy – hh:mm a').format(event.scheduledAt)),
            const SizedBox(height: 4),
            _infoRow(Icons.group,
                '${event.participants.length}/${event.maxParticipants} participants'),
            if (event.status == 'completed') ...[
              const SizedBox(height: 4),
              _infoRow(Icons.delete_sweep,
                  '${event.wasteCollected.toStringAsFixed(1)} kg collected, ${event.wasteRecycled.toStringAsFixed(1)} kg recycled'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (event.status == 'upcoming')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isParticipant
                          ? Colors.grey.shade200
                          : const Color(0xFF2E7D32),
                      foregroundColor:
                          isParticipant ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onJoin,
                    child: Text(isParticipant ? 'Leave' : 'Join Event'),
                  ),
                if (onUpdateStatus != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onUpdateStatus,
                    child: const Text('Update'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
      ],
    );
  }
}
