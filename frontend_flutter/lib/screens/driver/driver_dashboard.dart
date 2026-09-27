import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../profile/profile_screen.dart';
import 'today_schedule_screen.dart';
import 'today_route_screen.dart';
import 'recycling_weigh_in_screen.dart';
import 'pickup_detail_screen.dart';
import '../../models/pickup_model.dart';
import 'widgets/driver_bottom_navigation_bar.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  late int _selectedIndex = widget.initialIndex.clamp(0, 4).toInt();

  @override
  Widget build(BuildContext context) {
    const pages = [
      _DriverHome(),
      TodayRouteScreen(showBottomNavigationBar: false),
      TodayScheduleScreen(showBottomNavigationBar: false),
      RecyclingWeighInScreen(showBottomNavigationBar: false),
      ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: DriverBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _DriverHome extends StatefulWidget {
  const _DriverHome();

  @override
  State<_DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<_DriverHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DriverProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final name = context.watch<AuthProvider>().user?.name ?? 'Driver';
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Driver Dashboard'),
      ),
      body: provider.isDashboardLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: () => context.read<DriverProvider>().fetchDashboardData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(
                    name: name,
                    available: provider.isAvailable,
                    onChanged: (value) => context.read<DriverProvider>().toggleAvailability(),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Today, ${_todayLabel()}'),
                  const SizedBox(height: 10),
                  LayoutBuilder(builder: (context, constraints) {
                    final compact = constraints.maxWidth < 380;
                    final cards = [
                      _MetricCard(
                        label: 'Assigned pickups',
                        value: '${provider.totalPickups}',
                        icon: Icons.assignment_outlined,
                      ),
                      _MetricCard(
                        label: 'Completed pickups',
                        value: '${provider.completedPickups}',
                        icon: Icons.check_circle_outline,
                      ),
                      _MetricCard(
                        label: 'Remaining pickups',
                        value: '${provider.remainingPickups}',
                        icon: Icons.pending_actions_outlined,
                      ),
                    ];
                    return compact
                        ? Column(
                            children: cards
                                .map((card) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: card,
                                    ))
                                .toList(),
                          )
                        : Row(
                            children: [
                              for (final card in cards)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: card,
                                  ),
                                )
                            ],
                          );
                  }),
                  const SizedBox(height: 16),
                  _ProgressCard(provider: provider),
                  const SizedBox(height: 16),
                  _WeighInHistoryCard(totals: provider.weighInTotals, records: provider.weighInHistory),
                  const SizedBox(height: 16),
                  _SpecialRequestHistory(pickups: provider.specialRequestPickups),
                  const SizedBox(height: 16),
                  _TodayTasks(provider: provider),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
    );
  }

  static String _todayLabel() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.available, required this.onChanged});
  final String name;
  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.local_shipping, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(available ? 'Available for collection' : 'Currently unavailable'),
                ],
              ),
            ),
            Switch(value: available, activeColor: const Color(0xFF2E7D32), onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2E7D32)),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.provider});
  final DriverProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Collection progress'),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: provider.progressPercent / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF2E7D32),
              backgroundColor: const Color(0xFFE3EDE5),
            ),
            const SizedBox(height: 8),
            Text(
              '${provider.progressPercent}% complete · ${provider.completedRouteStops} of ${provider.totalRouteStops} route stops',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories, required this.totalWeight});
  final Map<String, double> categories;
  final double totalWeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Collected waste by category'),
            const SizedBox(height: 6),
            Text(
              '${totalWeight.toStringAsFixed(1)} kg total collected',
              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              const Text('No completed pickups today yet.')
            else
              ...categories.entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.recycling, color: Color(0xFF2E7D32)),
                  title: Text(_title(entry.key)),
                  trailing: Text(
                    '${entry.value.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _title(String value) =>
      value.isEmpty ? 'Other' : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.provider});
  final DriverProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Daily process summary'),
            const SizedBox(height: 10),
            _line('Assigned pickups', provider.totalPickups),
            _line('Completed pickups', provider.completedPickups),
            _line('Pending pickups', provider.remainingPickups),
            if (provider.cancelledPickups > 0)
              _line('Cancelled pickups', provider.cancelledPickups),
            _line('Collected weight', '${provider.totalCollectedWeight.toStringAsFixed(1)} kg'),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, Object value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TodayTasks extends StatelessWidget {
  const _TodayTasks({required this.provider});
  final DriverProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle("Today's pickup tasks"),
            const SizedBox(height: 8),
            if (provider.scheduleList.isEmpty)
              const Text('No special-request pickups assigned for today.')
            else
              ...provider.scheduleList.map(
                (pickup) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    pickup.status == 'completed'
                        ? Icons.check_circle
                        : Icons.location_on_outlined,
                    color: pickup.status == 'completed'
                        ? Colors.green
                        : const Color(0xFF2E7D32),
                  ),
                  title: Text(pickup.address),
                  subtitle: Text(
                    '${pickup.wasteType} · ${pickup.weightKg.toStringAsFixed(1)} kg',
                  ),
                  trailing: Text(pickup.status),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PickupDetailScreen(pickup: pickup)),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TodayScheduleScreen(initialTab: 1)),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('View today\'s other pickups'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _StopSummaryCard extends StatelessWidget {
  const _StopSummaryCard({required this.summary});
  final Map<String, int> summary;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle('Assigned route stops'),
            const SizedBox(height: 8),
            for (final item in const [('Assigned', 'assigned'), ('Completed', 'completed'), ('Remaining', 'remaining'), ('Collected', 'collected')])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(item.$1), Text('${summary[item.$2] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
          ]),
        ),
      );
}

class _WeighInHistoryCard extends StatelessWidget {
  const _WeighInHistoryCard({required this.totals, required this.records});
  final Map<String, double> totals;
  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    const labels = {'organic': 'Organic', 'plasticPaper': 'Plastic & paper', 'glassOthers': 'Glass & others'};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionTitle('Recycling weights by category'),
          const SizedBox(height: 8),
          for (final entry in labels.entries)
            ListTile(contentPadding: EdgeInsets.zero, title: Text(entry.value), trailing: Text('${(totals[entry.key] ?? 0).toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(),
          const Text('Weigh-in history', style: TextStyle(fontWeight: FontWeight.w600)),
          if (records.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('No weigh-in records yet.')),
          for (final record in records)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.scale_outlined, color: Color(0xFF2E7D32)),
              title: Text(_recordDate(record['recordedAt'] ?? record['createdAt'])),
              subtitle: Text(_recordDetails(record)),
              trailing: Text('${_recordTotal(record['weightsKg'])} kg'),
            ),
        ]),
      ),
    );
  }

  static String _recordTotal(dynamic weights) {
    if (weights is! Map) return '0.0';
    return weights.values.fold<double>(0, (sum, value) => sum + ((value as num?)?.toDouble() ?? 0)).toStringAsFixed(1);
  }

  static String _recordDetails(Map<String, dynamic> record) {
    final weights = record['weightsKg'] is Map ? record['weightsKg'] as Map : const {};
    final route = record['route'] is Map
        ? (record['route']['routeName'] ?? record['route']['zone'])?.toString()
        : null;
    final lines = [
      'Organic: ${((weights['organic'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} kg',
      'Plastic & paper: ${((weights['plasticPaper'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} kg',
      'Glass & others: ${((weights['glassOthers'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} kg',
    ];
    final context = route?.isNotEmpty == true
        ? route!
        : record['notes']?.toString().trim().isNotEmpty == true
            ? record['notes'].toString().trim()
            : 'End of day weigh-in';
    return '$context\n${lines.join(' · ')}';
  }

  static String _recordDate(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return 'Recorded weigh-in';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _SpecialRequestHistory extends StatelessWidget {
  const _SpecialRequestHistory({required this.pickups});
  final List<PickupModel> pickups;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle('Special-request pickup history'),
            if (pickups.isEmpty) const Padding(padding: EdgeInsets.only(top: 10), child: Text('No special-request pickups yet.')),
            for (final pickup in pickups)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(pickup.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${pickup.address}\n${pickup.pickupNumber} · ${pickup.status}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PickupDetailScreen(pickup: pickup))),
              ),
          ]),
        ),
      );
}
