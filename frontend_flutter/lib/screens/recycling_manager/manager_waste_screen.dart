import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/manager_provider.dart';
import '../../models/collection_request_model.dart';

// =====================================================
// CONSTANTS & HELPERS
// =====================================================

const _teal = Color(0xFF0097A7);
const _tealLight = Color(0xFFDDF7F8);
const _bg = Color(0xFFF7FBFB);
const _green = Color(0xFF2E9B72);
const _orange = Color(0xFFDE9B3C);
const _blue = Color(0xFF4D8CC9);
const _red = Color(0xFFE46B56);

final _fmt = DateFormat('dd MMM yyyy');
final _fmtFull = DateFormat('dd MMM yyyy, h:mm a');

double _numOf(dynamic v, [double def = 0]) {
  if (v == null) return def;
  return (v as num).toDouble();
}

String _fmtKg(double kg) {
  if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)} t';
  return '${kg.toStringAsFixed(1)} kg';
}

String _processingLabel(String? s) {
  switch (s) {
    case 'received':      return 'Received';
    case 'sorted':        return 'Sorted';
    case 'recyclable':    return 'Recyclable';
    case 'non_recyclable':return 'Non-Recyclable';
    case 'processed':     return 'Processed';
    case 'recycled':      return 'Recycled';
    case 'disposed':      return 'Disposed';
    default:              return 'Pending';
  }
}

Color _processingColor(String? s) {
  switch (s) {
    case 'received':      return _blue;
    case 'sorted':        return _orange;
    case 'recyclable':    return _green;
    case 'non_recyclable':return _red;
    case 'processed':     return const Color(0xFF8066B3);
    case 'recycled':      return _green;
    case 'disposed':      return Colors.grey;
    default:              return Colors.grey.shade400;
  }
}

IconData _wasteIcon(String? t) {
  return CollectionRequest.getWasteTypeIcon(t ?? 'other');
}

Color _wasteColor(String? t) {
  switch (t) {
    case 'organic':    return _green;
    case 'plastic':    return _blue;
    case 'paper':      return _orange;
    case 'glass':      return const Color(0xFF80DEEA);
    case 'metal':      return Colors.blueGrey;
    case 'electronic': return const Color(0xFF8066B3);
    case 'hazardous':  return _red;
    default:           return Colors.grey;
  }
}

// =====================================================
// MAIN SCREEN
// =====================================================

class ManagerWasteScreen extends StatefulWidget {
  const ManagerWasteScreen({super.key});

  @override
  State<ManagerWasteScreen> createState() => _ManagerWasteScreenState();
}

class _ManagerWasteScreenState extends State<ManagerWasteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ManagerProvider>();
      p.fetchReceivedWaste(refresh: true);
      p.fetchWasteWeighIns();
      p.fetchWasteReport(period: 'daily');
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text(
          'Waste Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined), text: 'Receiving'),
            Tab(icon: Icon(Icons.recycling), text: 'Processing'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _ReceivingTab(),
          _ProcessingTab(),
          _ReportsTab(),
        ],
      ),
    );
  }
}

// =====================================================
// TAB 1: WASTE RECEIVING
// =====================================================

class _ReceivingTab extends StatefulWidget {
  const _ReceivingTab();

  @override
  State<_ReceivingTab> createState() => _ReceivingTabState();
}

class _ReceivingTabState extends State<_ReceivingTab> {
  final _searchCtrl = TextEditingController();
  String? _selectedType;

  static const _types = [
    'organic', 'plastic', 'paper', 'glass', 'metal', 'electronic', 'hazardous', 'other'
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<ManagerProvider>().setWasteFilters(
      wasteType: _selectedType,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _searchCtrl.clear();
    });
    context.read<ManagerProvider>().clearWasteFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerProvider>(
      builder: (context, provider, _) {
        final items = provider.receivedWaste;
        final weighIns = provider.wasteWeighIns;

        // Summary totals from received items
        double totalReceived = 0;
        double totalRecycled = 0;
        double totalDisposed = 0;
        for (final r in items) {
          totalReceived += _numOf(r['collectedQuantity']) > 0
              ? _numOf(r['collectedQuantity'])
              : _numOf(r['estimatedQuantity']);
          totalRecycled += _numOf(r['recycledQuantity']);
          totalDisposed += _numOf(r['disposedQuantity']);
        }

        // Weigh-in totals
        double organic = 0, plasticPaper = 0, glassOthers = 0;
        for (final w in weighIns) {
          final wk = w['weightsKg'];
          if (wk is Map) {
            organic += _numOf(wk['organic']);
            plasticPaper += _numOf(wk['plasticPaper']);
            glassOthers += _numOf(wk['glassOthers']);
          }
        }
        final totalWeighIn = organic + plasticPaper + glassOthers;

        return RefreshIndicator(
          color: _teal,
          onRefresh: () async {
            await provider.fetchReceivedWaste(refresh: true);
            await provider.fetchWasteWeighIns();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              _SectionTitle('Overview'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MetricCard('Total Received', _fmtKg(totalReceived + totalWeighIn), Icons.download_outlined, _teal)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricCard('Recycled', _fmtKg(totalRecycled), Icons.recycling, _green)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MetricCard('Disposed', _fmtKg(totalDisposed), Icons.delete_outline, _orange)),
                  const SizedBox(width: 10),
                  Expanded(child: _MetricCard('Records', '${items.length}', Icons.list_alt_outlined, _blue)),
                ],
              ),

              // Driver weigh-ins section
              if (weighIns.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionTitle('Driver Weigh-In Records (${weighIns.length})'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _WeighInChip('Organic', _fmtKg(organic), _green)),
                          Expanded(child: _WeighInChip('Plastic/Paper', _fmtKg(plasticPaper), _blue)),
                          Expanded(child: _WeighInChip('Glass/Others', _fmtKg(glassOthers), _orange)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      ...weighIns.take(3).map((w) => _WeighInTile(weighIn: w)),
                      if (weighIns.length > 3)
                        Center(
                          child: TextButton(
                            onPressed: () => _showAllWeighIns(context, weighIns),
                            child: Text(
                              'View all ${weighIns.length} records',
                              style: const TextStyle(color: _teal),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // Collection request history
              const SizedBox(height: 20),
              _SectionTitle('Incoming Waste History (${provider.totalReceivedWaste})'),
              const SizedBox(height: 8),

              // Filters
              _SearchBar(
                controller: _searchCtrl,
                onChanged: (_) => _applyFilters(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DropdownFilter(
                      value: _selectedType,
                      hint: 'All categories',
                      items: _types,
                      labelBuilder: (s) => s[0].toUpperCase() + s.substring(1),
                      onChanged: (v) {
                        setState(() => _selectedType = v);
                        _applyFilters();
                      },
                    ),
                  ),
                  if (_selectedType != null || _searchCtrl.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 16, color: _red),
                      label: const Text('Clear', style: TextStyle(color: _red)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Error state
              if (provider.wasteError != null)
                _ErrorBanner(provider.wasteError!, onRetry: () => provider.fetchReceivedWaste(refresh: true)),

              // Loading state
              if (provider.isLoadingReceivedWaste)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: _teal)),
                )
              else if (items.isEmpty)
                _EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No received waste',
                  subtitle: 'Collected waste records from drivers will appear here.',
                )
              else
                ...items.map((r) => _ReceivedWasteTile(request: r)),
            ],
          ),
        );
      },
    );
  }

  void _showAllWeighIns(BuildContext context, List<Map<String, dynamic>> weighIns) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            const Text('All Driver Weigh-Ins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                children: weighIns.map((w) => _WeighInTile(weighIn: w)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// TAB 2: WASTE PROCESSING
// =====================================================

class _ProcessingTab extends StatefulWidget {
  const _ProcessingTab();

  @override
  State<_ProcessingTab> createState() => _ProcessingTabState();
}

class _ProcessingTabState extends State<_ProcessingTab> {
  String? _filterProcessingStatus;

  static const _statuses = [
    'received', 'sorted', 'recyclable', 'non_recyclable', 'processed', 'recycled', 'disposed'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerProvider>(
      builder: (context, provider, _) {
        final items = provider.receivedWaste;

        return RefreshIndicator(
          color: _teal,
          onRefresh: () => provider.fetchReceivedWaste(refresh: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionTitle('Processing Queue (${items.length})'),
              const SizedBox(height: 8),

              // Status filter chips
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filterProcessingStatus == null,
                      onTap: () {
                        setState(() => _filterProcessingStatus = null);
                        provider.setWasteFilters();
                      },
                    ),
                    ..._statuses.map((s) => _FilterChip(
                      label: _processingLabel(s),
                      selected: _filterProcessingStatus == s,
                      color: _processingColor(s),
                      onTap: () {
                        setState(() => _filterProcessingStatus = s);
                        provider.setWasteFilters(processingStatus: s);
                      },
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (provider.wasteError != null)
                _ErrorBanner(provider.wasteError!, onRetry: () => provider.fetchReceivedWaste(refresh: true)),

              if (provider.isLoadingReceivedWaste)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: _teal)),
                )
              else if (items.isEmpty)
                _EmptyState(
                  icon: Icons.recycling,
                  title: 'No items to process',
                  subtitle: 'Collected waste records will appear here for processing.',
                )
              else
                ...items.map((r) => _ProcessingTile(request: r)),
            ],
          ),
        );
      },
    );
  }
}

// =====================================================
// TAB 3: REPORTS
// =====================================================

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerProvider>(
      builder: (context, provider, _) {
        final r = provider.wasteReport;
        final today = r['today'] is Map ? Map<String, dynamic>.from(r['today'] as Map) : <String, dynamic>{};
        final weighInTotals = r['weighInTotals'] is Map ? Map<String, dynamic>.from(r['weighInTotals'] as Map) : <String, dynamic>{};
        final byCategory = r['byCategory'] is List ? r['byCategory'] as List : [];

        final totalReceived = _numOf(r['totalReceived']);
        final totalRecycled = _numOf(r['totalRecycled']);
        final totalDisposed = _numOf(r['totalDisposed']);
        final recyclingPct = _numOf(r['recyclingPercentage']);
        final totalRecords = (r['totalRecords'] as num?)?.toInt() ?? 0;

        return RefreshIndicator(
          color: _teal,
          onRefresh: () => provider.fetchWasteReport(period: _period),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period selector
              Row(
                children: [
                  const Text('Period:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  ...['daily', 'weekly', 'monthly'].map((p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p[0].toUpperCase() + p.substring(1)),
                      selected: _period == p,
                      selectedColor: _tealLight,
                      labelStyle: TextStyle(
                        color: _period == p ? _teal : Colors.grey.shade700,
                        fontWeight: _period == p ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => _period = p);
                        provider.fetchWasteReport(period: p);
                      },
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 16),

              if (provider.isLoadingWasteReport)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: _teal),
                ))
              else ...[
                // Summary cards
                _SectionTitle('${_period[0].toUpperCase() + _period.substring(1)} Summary ($totalRecords records)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _MetricCard('Total Received', _fmtKg(totalReceived), Icons.download_outlined, _teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricCard('Recycled', _fmtKg(totalRecycled), Icons.recycling, _green)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _MetricCard('Disposed', _fmtKg(totalDisposed), Icons.delete_outline, _orange)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricCard('Recycling %', '${recyclingPct.toStringAsFixed(1)}%', Icons.percent, _blue)),
                  ],
                ),

                // Recycling % gauge
                const SizedBox(height: 20),
                _SectionTitle('Recycling Rate'),
                const SizedBox(height: 8),
                _RecyclingGauge(percentage: recyclingPct),

                // Today's stats
                const SizedBox(height: 20),
                _SectionTitle("Today's Activity"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _MetricCard('Received', _fmtKg(_numOf(today['totalReceived'])), Icons.inbox_outlined, _teal)),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricCard('Recycled', _fmtKg(_numOf(today['totalRecycled'])), Icons.recycling, _green)),
                  ],
                ),

                // Driver weigh-in totals
                if (weighInTotals.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionTitle('Driver End-of-Day Submissions'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weighInTotals['totalWeighIns'] ?? 0} weigh-in(s) for this period',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        _CategoryBar('Organic', _numOf(weighInTotals['organic']), _green),
                        _CategoryBar('Plastic / Paper', _numOf(weighInTotals['plasticPaper']), _blue),
                        _CategoryBar('Glass / Others', _numOf(weighInTotals['glassOthers']), _orange),
                      ],
                    ),
                  ),
                ],

                // By category
                if (byCategory.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionTitle('Collection Statistics by Category'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: byCategory.map((c) {
                        final cat = c['category'] as String? ?? 'other';
                        final weight = _numOf(c['totalWeight']);
                        final count = (c['count'] as num?)?.toInt() ?? 0;
                        final maxWeight = byCategory.fold<double>(
                            0, (prev, el) => _numOf(el['totalWeight']) > prev ? _numOf(el['totalWeight']) : prev);
                        return _CategoryStatRow(
                          category: cat,
                          weight: weight,
                          count: count,
                          maxWeight: maxWeight,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

// =====================================================
// TILES
// =====================================================

class _ReceivedWasteTile extends StatelessWidget {
  final Map<String, dynamic> request;

  const _ReceivedWasteTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final wasteType = request['wasteType'] as String? ?? 'other';
    final location = request['location'] as String? ?? '—';
    final status = request['processingStatus'] as String?;
    final collected = _numOf(request['collectedQuantity']) > 0
        ? _numOf(request['collectedQuantity'])
        : _numOf(request['estimatedQuantity']);
    final driverMap = request['assignedDriver'];
    final driverName = driverMap is Map ? driverMap['name'] as String? : null;
    final updatedAt = request['updatedAt'] != null
        ? DateTime.tryParse(request['updatedAt'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _wasteColor(wasteType).withValues(alpha: 0.12),
            child: Icon(_wasteIcon(wasteType), color: _wasteColor(wasteType), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(_processingLabel(status), _processingColor(status)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${wasteType[0].toUpperCase()}${wasteType.substring(1)}  ·  ${_fmtKg(collected)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (driverName != null)
                  Text(
                    'Driver: $driverName',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                if (updatedAt != null)
                  Text(
                    'Collected: ${_fmt.format(updatedAt)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingTile extends StatelessWidget {
  final Map<String, dynamic> request;

  const _ProcessingTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final id = request['_id'] as String? ?? '';
    final wasteType = request['wasteType'] as String? ?? 'other';
    final location = request['location'] as String? ?? '—';
    final procStatus = request['processingStatus'] as String?;
    final recyclableStatus = request['recyclableStatus'] as String?;
    final received = _numOf(request['collectedQuantity']) > 0
        ? _numOf(request['collectedQuantity'])
        : _numOf(request['estimatedQuantity']);
    final recycled = _numOf(request['recycledQuantity']);
    final disposed = _numOf(request['disposedQuantity']);
    final driverMap = request['assignedDriver'];
    final driverName = driverMap is Map ? driverMap['name'] as String? : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            backgroundColor: _wasteColor(wasteType).withValues(alpha: 0.12),
            child: Icon(_wasteIcon(wasteType), color: _wasteColor(wasteType), size: 20),
          ),
          title: Text(location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${wasteType[0].toUpperCase()}${wasteType.substring(1)}  ·  ${_fmtKg(received)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              if (driverName != null)
                Text('Driver: $driverName', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          trailing: _StatusBadge(_processingLabel(procStatus), _processingColor(procStatus)),
          children: [
            const Divider(),
            // Status pills
            _SectionLabel('Processing Status'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['received', 'sorted', 'recyclable', 'non_recyclable', 'processed', 'recycled', 'disposed']
                  .map((s) => _SelectableStatusChip(
                    label: _processingLabel(s),
                    selected: procStatus == s,
                    color: _processingColor(s),
                    onTap: () => _updateStatus(context, id, s, received),
                  ))
                  .toList(),
            ),

            // Recyclable status
            const SizedBox(height: 10),
            _SectionLabel('Recyclable Status'),
            const SizedBox(height: 6),
            Row(
              children: [
                _SelectableStatusChip(
                  label: 'Recyclable',
                  selected: recyclableStatus == 'recyclable',
                  color: _green,
                  onTap: () => _updateRecyclableStatus(context, id, 'recyclable'),
                ),
                const SizedBox(width: 6),
                _SelectableStatusChip(
                  label: 'Non-Recyclable',
                  selected: recyclableStatus == 'non_recyclable',
                  color: _red,
                  onTap: () => _updateRecyclableStatus(context, id, 'non_recyclable'),
                ),
              ],
            ),

            // Quantities
            const SizedBox(height: 12),
            _SectionLabel('Quantities (Received: ${_fmtKg(received)})'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _QuantityField(
                    label: 'Recycled (kg)',
                    initial: recycled > 0 ? recycled.toStringAsFixed(1) : '',
                    maxValue: received,
                    onSave: (v) => _updateQuantities(context, id, recycled: v, disposed: disposed > 0 ? disposed : null, received: received),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuantityField(
                    label: 'Disposed (kg)',
                    initial: disposed > 0 ? disposed.toStringAsFixed(1) : '',
                    maxValue: received,
                    onSave: (v) => _updateQuantities(context, id, recycled: recycled > 0 ? recycled : null, disposed: v, received: received),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String id, String status, double received) async {
    final provider = context.read<ManagerProvider>();
    final ok = await provider.updateWasteProcessing(requestId: id, processingStatus: status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Status updated to ${_processingLabel(status)}' : (provider.wasteError ?? 'Update failed')),
      backgroundColor: ok ? _green : _red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _updateRecyclableStatus(BuildContext context, String id, String status) async {
    final provider = context.read<ManagerProvider>();
    final ok = await provider.updateWasteProcessing(requestId: id, recyclableStatus: status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Recyclable status updated' : (provider.wasteError ?? 'Update failed')),
      backgroundColor: ok ? _green : _red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _updateQuantities(BuildContext context, String id, {double? recycled, double? disposed, required double received}) async {
    // Validate cross total
    final r = recycled ?? 0;
    final d = disposed ?? 0;
    if (r + d > received) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Total quantities exceed received weight'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final provider = context.read<ManagerProvider>();
    final ok = await provider.updateWasteProcessing(
      requestId: id,
      recycledQuantity: recycled,
      disposedQuantity: disposed,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Quantities saved' : (provider.wasteError ?? 'Update failed')),
      backgroundColor: ok ? _green : _red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class _WeighInTile extends StatelessWidget {
  final Map<String, dynamic> weighIn;

  const _WeighInTile({required this.weighIn});

  @override
  Widget build(BuildContext context) {
    final driverMap = weighIn['driver'];
    final driverName = driverMap is Map ? driverMap['name'] as String? : null;
    final routeMap = weighIn['route'];
    final routeName = routeMap is Map ? routeMap['routeName'] as String? : null;
    final recordedAt = weighIn['recordedAt'] != null
        ? DateTime.tryParse(weighIn['recordedAt'].toString())
        : null;
    final wk = weighIn['weightsKg'];
    final organic = wk is Map ? _numOf(wk['organic']) : 0.0;
    final plastic = wk is Map ? _numOf(wk['plasticPaper']) : 0.0;
    final glass = wk is Map ? _numOf(wk['glassOthers']) : 0.0;
    final total = organic + plastic + glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _teal.withValues(alpha: 0.12),
            child: const Icon(Icons.scale_outlined, color: _teal, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName ?? 'Driver',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  [
                    routeName,
                    if (recordedAt != null) _fmtFull.format(recordedAt),
                  ].whereType<String>().join('  ·  '),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                Text(
                  'Organic: ${_fmtKg(organic)}  ·  Plastic/Paper: ${_fmtKg(plastic)}  ·  Glass/Others: ${_fmtKg(glass)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(_fmtKg(total), style: const TextStyle(fontWeight: FontWeight.bold, color: _teal)),
        ],
      ),
    );
  }
}

// =====================================================
// REUSABLE WIDGETS
// =====================================================

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600));
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SelectableStatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SelectableStatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color = _teal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuantityField extends StatefulWidget {
  final String label;
  final String initial;
  final double maxValue;
  final void Function(double) onSave;

  const _QuantityField({
    required this.label,
    required this.initial,
    required this.maxValue,
    required this.onSave,
  });

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        suffixIcon: IconButton(
          icon: const Icon(Icons.check, size: 18, color: _teal),
          onPressed: () {
            final v = double.tryParse(_ctrl.text);
            if (v == null || v < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter a valid quantity'), behavior: SnackBarBehavior.floating),
              );
              return;
            }
            if (v > widget.maxValue) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cannot exceed ${_fmtKg(widget.maxValue)}'), behavior: SnackBarBehavior.floating),
              );
              return;
            }
            FocusScope.of(context).unfocus();
            widget.onSave(v);
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by location…',
        hintStyle: const TextStyle(fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: _teal),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final String Function(String) labelBuilder;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          isExpanded: true,
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(labelBuilder(s), style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner(this.message, {required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: _red, fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(color: _red))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RecyclingGauge extends StatelessWidget {
  final double percentage;

  const _RecyclingGauge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final pct = percentage.clamp(0, 100).toDouble();
    Color color = _red;
    if (pct >= 60) { color = _green; }
    else if (pct >= 30) { color = _orange; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text('of waste recycled', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 60 ? '🌟 Great recycling rate!' : pct >= 30 ? '📈 Keep improving!' : '⚠️ Low recycling rate',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _CategoryBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value > 0 ? (value / (value + 1)).clamp(0.05, 1.0) : 0,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(_fmtKg(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CategoryStatRow extends StatelessWidget {
  final String category;
  final double weight;
  final int count;
  final double maxWeight;

  const _CategoryStatRow({
    required this.category,
    required this.weight,
    required this.count,
    required this.maxWeight,
  });

  @override
  Widget build(BuildContext context) {
    final label = category[0].toUpperCase() + category.substring(1);
    final ratio = maxWeight > 0 ? (weight / maxWeight).clamp(0.0, 1.0) : 0.0;
    final color = _wasteColor(category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_wasteIcon(category), color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ],
              ),
              Text('$count records  ·  ${_fmtKg(weight)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeighInChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WeighInChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }
}
