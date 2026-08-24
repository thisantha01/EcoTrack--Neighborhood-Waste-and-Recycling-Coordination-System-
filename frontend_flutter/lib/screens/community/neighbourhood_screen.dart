import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';

class NeighbourhoodScreen extends StatefulWidget {
  const NeighbourhoodScreen({super.key});

  @override
  State<NeighbourhoodScreen> createState() => _NeighbourhoodScreenState();
}

class _NeighbourhoodScreenState extends State<NeighbourhoodScreen> {
  final AnnouncementService _service = AnnouncementService();
  List<Announcement> _items = [];
  bool _loading = true;
  String? _error;
  String _selectedType = 'all';

  final _types = [
    {'value': 'all', 'label': 'All', 'icon': Icons.list},
    {'value': 'announcement', 'label': 'Announcements', 'icon': Icons.campaign},
    {'value': 'group_collection', 'label': 'Group Collection', 'icon': Icons.group_work},
    {'value': 'pickup_schedule', 'label': 'Pickup Schedule', 'icon': Icons.schedule},
    {'value': 'activity', 'label': 'Activities', 'icon': Icons.event},
  ];

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
      final items = await _service.getAnnouncements(
        type: _selectedType == 'all' ? null : _selectedType,
      );
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String type = 'announcement';

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
                  '📢 Create Announcement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    {'value': 'announcement', 'label': '📢 Announcement'},
                    {'value': 'group_collection', 'label': '♻️ Group Collection'},
                    {'value': 'pickup_schedule', 'label': '🚛 Pickup Schedule'},
                    {'value': 'activity', 'label': '🎉 Activity'},
                  ]
                      .map((t) => DropdownMenuItem<String>(
                            value: t['value'],
                            child: Text(t['label']!),
                          ))
                      .toList(),
                  onChanged: (v) => setModal(() => type = v ?? 'announcement'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Content / Details',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Location (optional)',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
                          contentCtrl.text.trim().isEmpty) return;
                      try {
                        await _service.createAnnouncement(
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          type: type,
                          location: locationCtrl.text.trim().isEmpty
                              ? null
                              : locationCtrl.text.trim(),
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
                    child: const Text('Post Announcement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true) _load();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'group_collection':
        return const Color(0xFF1565C0);
      case 'pickup_schedule':
        return const Color(0xFF6A1B9A);
      case 'activity':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'group_collection':
        return '♻️ Group Collection';
      case 'pickup_schedule':
        return '🚛 Pickup Schedule';
      case 'activity':
        return '🎉 Activity';
      default:
        return '📢 Announcement';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('🏘️ Neighbourhood',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Announce'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 52,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _types.map((t) {
                final isSelected = _selectedType == t['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t['label'] as String),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedType = t['value'] as String);
                      _load();
                    },
                    selectedColor: const Color(0xFFE8F5E9),
                    checkmarkColor: const Color(0xFF2E7D32),
                  ),
                );
              }).toList(),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.groups,
                                    size: 64, color: Color(0xFF2E7D32)),
                                SizedBox(height: 16),
                                Text('No announcements yet',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: const Color(0xFF2E7D32),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              itemBuilder: (ctx, i) {
                                final item = _items[i];
                                final color = _typeColor(item.type);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: color.withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border:
                                                    Border.all(color: color),
                                              ),
                                              child: Text(
                                                _typeLabel(item.type),
                                                style: TextStyle(
                                                    color: color,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              DateFormat('MMM d').format(item.createdAt),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(item.content,
                                            style: const TextStyle(
                                                color: Colors.grey)),
                                        if (item.location.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 14,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(item.location,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                                  const Color(0xFF2E7D32),
                                              child: Text(
                                                item.author.name.isNotEmpty
                                                    ? item.author.name[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.author.name,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
