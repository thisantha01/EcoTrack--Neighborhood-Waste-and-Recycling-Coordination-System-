import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/manager_provider.dart';
import '../../models/collection_request_model.dart';
import 'manager_assignment_screen.dart';
import 'manager_request_map_screen.dart';
import 'request_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  THEME CONSTANTS (Recycling Manager Teal Palette)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFF0097A7);
  static const dark       = Color(0xFF00838F);
  static const light      = Color(0xFFE0F7FA);
  static const bg         = Color(0xFFF4F8F9);
  static const surface    = Colors.white;
  static const textDark   = Color(0xFF1A2B35);
  static const textMid    = Color(0xFF546E7A);
  static const textLight  = Color(0xFF90A4AE);
  static const border     = Color(0xFFE8EDEF);
  static const shadow     = Color(0x08000000);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILTER ENUMS
// ─────────────────────────────────────────────────────────────────────────────
enum _StatusFilter {
  all('All Statuses'),
  pending('Pending'),
  scheduled('Scheduled'),
  collected('Collected'),
  cancelled('Cancelled');

  final String label;
  const _StatusFilter(this.label);
}

enum _DatePeriod {
  allTime('All Time'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  customRange('Custom Range');

  final String label;
  const _DatePeriod(this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS CONFIGURATION (Used by the existing RequestCard)
// ─────────────────────────────────────────────────────────────────────────────
class _StatusItem {
  final String? filterKey;
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatusItem({
    required this.filterKey,
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  static const all = _StatusItem(
    filterKey: null,
    label: 'All',
    color: _T.primary,
    bg: _T.light,
    icon: Icons.apps_rounded,
  );
  static const pending = _StatusItem(
    filterKey: 'requested',
    label: 'Pending',
    color: Color(0xFFE65100),
    bg: Color(0xFFFFF3E0),
    icon: Icons.hourglass_top_rounded,
  );
  static const scheduled = _StatusItem(
    filterKey: 'scheduled',
    label: 'Scheduled',
    color: Color(0xFF5C35A0),
    bg: Color(0xFFEDE7F6),
    icon: Icons.schedule_rounded,
  );
  static const collected = _StatusItem(
    filterKey: 'collected',
    label: 'Collected',
    color: Color(0xFF2E7D32),
    bg: Color(0xFFE8F5E9),
    icon: Icons.check_circle_rounded,
  );
  static const cancelled = _StatusItem(
    filterKey: 'cancelled',
    label: 'Cancelled',
    color: Color(0xFFC62828),
    bg: Color(0xFFFFEBEE),
    icon: Icons.cancel_rounded,
  );


  static _StatusItem forStatus(String status) {
    switch (status) {
      case 'requested':
        return pending;
      case 'accepted':
      case 'scheduled':
        return scheduled;
      case 'collected':
        return collected;
      case 'cancelled':
        return cancelled;
      default:
        return all;
    }
  }

  static String labelForStatus(String status) {
    switch (status) {
      case 'requested':
        return 'Pending';
      case 'accepted':
      case 'scheduled':
        return 'Scheduled';
      case 'collected':
        return 'Collected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CollectionRequestsScreen extends StatefulWidget {
  const CollectionRequestsScreen({super.key});

  @override
  State<CollectionRequestsScreen> createState() => _CollectionRequestsScreenState();
}

class _CollectionRequestsScreenState extends State<CollectionRequestsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  _DatePeriod _datePeriod = _DatePeriod.allTime;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerProvider>().fetchCollectionRequests(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      final provider = context.read<ManagerProvider>();
      if (provider.hasMore && !provider.isLoadingRequests) {
        provider.fetchCollectionRequests();
      }
    }
  }

  void _refresh() {
    context.read<ManagerProvider>().fetchCollectionRequests(refresh: true);
  }

  // ── Date helper ──────────────────────────────────────────────────────────
  DateTime _reqDate(CollectionRequest r) {
    final d = r.preferredDate ?? r.createdAt;
    return DateTime(d.year, d.month, d.day);
  }

  bool _matchesDatePeriod(CollectionRequest r) {
    if (_datePeriod == _DatePeriod.allTime) return true;

    final d = _reqDate(r);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_datePeriod) {
      case _DatePeriod.allTime:
        return true;

      case _DatePeriod.today:
        return d == today;

      case _DatePeriod.thisWeek:
        final wkMon = today.subtract(Duration(days: today.weekday - 1));
        final wkSun = wkMon.add(const Duration(days: 6));
        return !d.isBefore(wkMon) && !d.isAfter(wkSun);

      case _DatePeriod.thisMonth:
        return d.year == now.year && d.month == now.month;

      case _DatePeriod.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1);
        return d.year == lastMonthDate.year && d.month == lastMonthDate.month;

      case _DatePeriod.customRange:
        if (_customStartDate != null && d.isBefore(_customStartDate!)) return false;
        if (_customEndDate != null && d.isAfter(_customEndDate!)) return false;
        return true;
    }
  }

  bool _matchesStatus(CollectionRequest r) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.pending:
        return r.status == 'requested';
      case _StatusFilter.scheduled:
        return r.status == 'scheduled' || r.status == 'accepted';
      case _StatusFilter.collected:
        return r.status == 'collected';
      case _StatusFilter.cancelled:
        return r.status == 'cancelled';
    }
  }

  // ── Filter Logic ─────────────────────────────────────────────────────────
  List<CollectionRequest> _filter(List<CollectionRequest> src) {
    return src.where((r) {
      // 1. Status Filter
      if (!_matchesStatus(r)) return false;

      // 2. Date / Period Filter
      if (!_matchesDatePeriod(r)) return false;

      // 3. Search query
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final residentName = (r.requester?.name ?? r.requesterName).toLowerCase();
      final location = r.location.toLowerCase();
      final waste = r.wasteTypeLabel.toLowerCase();
      final driver = (r.assignedDriver?.name ?? '').toLowerCase();

      return residentName.contains(q) ||
          location.contains(q) ||
          waste.contains(q) ||
          driver.contains(q);
    }).toList();
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _statusFilter != _StatusFilter.all ||
        _datePeriod != _DatePeriod.allTime;
  }

  void _resetAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _statusFilter = _StatusFilter.all;
      _datePeriod = _DatePeriod.allTime;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  // Small center dialog date picker (NO separate page navigation)
  Future<void> _pickSingleDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_customStartDate ?? now.subtract(const Duration(days: 30)))
        : (_customEndDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _T.primary,
              onPrimary: Colors.white,
              onSurface: _T.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStartDate = DateTime(picked.year, picked.month, picked.day);
          if (_customEndDate != null && _customEndDate!.isBefore(_customStartDate!)) {
            _customEndDate = _customStartDate;
          }
        } else {
          _customEndDate = DateTime(picked.year, picked.month, picked.day);
          if (_customStartDate != null && _customStartDate!.isAfter(_customEndDate!)) {
            _customStartDate = _customEndDate;
          }
        }
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Collection Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _refresh,
            tooltip: 'Refresh Requests',
          ),
        ],
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, _) {
          final allRequests = provider.requests;
          final filteredRequests = _filter(allRequests);

          return Column(
            children: [
              // Clean Page-Level Filters: [ Search ] [ Status ▼ ] [ Date / Period ▼ ] [ Clear ]
              _buildPageFilters(),

              // Summary Section
              _buildSummarySection(allRequests.length, filteredRequests),

              // Content Area (Existing request cards receive the filtered results)
              Expanded(
                child: provider.isLoadingRequests && allRequests.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: _T.primary),
                      )
                    : provider.error != null && allRequests.isEmpty
                        ? _buildErrorView(provider)
                        : filteredRequests.isEmpty
                            ? _buildEmptyView(allRequests.isNotEmpty)
                            : _buildRequestsList(filteredRequests, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Page-Level Filter Area: [ Search ] [ Status ▼ ] [ Date / Period ▼ ] [ Clear ]
  Widget _buildPageFilters() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Box
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 13.5, color: _T.textDark),
              decoration: InputDecoration(
                hintText: 'Search resident, address, waste type, driver...',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _T.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: _T.textMid),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Filter Controls Row: [ Status ▼ ]  [ Date / Period ▼ ]  [ Clear ]
          Row(
            children: [
              // [ Status ▼ ]
              Expanded(
                flex: 5,
                child: _buildStatusDropdown(),
              ),
              const SizedBox(width: 8),

              // [ Date / Period ▼ ]
              Expanded(
                flex: 6,
                child: _buildDatePeriodDropdown(),
              ),
              const SizedBox(width: 8),

              // [ Clear ]
              _buildClearButton(),
            ],
          ),

          // 3. Compact Inline Custom Range Picker (Appears right here on the same page!)
          if (_datePeriod == _DatePeriod.customRange)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    // From Date Button
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickSingleDate(isStart: true),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 13, color: _T.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _customStartDate != null
                                      ? 'From: ${DateFormat('MMM d, yyyy').format(_customStartDate!)}'
                                      : 'From Date',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _T.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: _T.textMid),
                    ),
                    // To Date Button
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickSingleDate(isStart: false),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 34,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 13, color: _T.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _customEndDate != null
                                      ? 'To: ${DateFormat('MMM d, yyyy').format(_customEndDate!)}'
                                      : 'To Date',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _T.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Status Dropdown Button (Matching Manager Theme Colors)
  Widget _buildStatusDropdown() {
    final isFiltered = _statusFilter != _StatusFilter.all;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFiltered ? _T.primary : Colors.grey.shade300,
          width: isFiltered ? 1.4 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_StatusFilter>(
          value: _statusFilter,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: _T.dark,
            size: 22,
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _T.textDark,
          ),
          onChanged: (val) {
            if (val != null) setState(() => _statusFilter = val);
          },
          items: _StatusFilter.values.map((s) {
            return DropdownMenuItem<_StatusFilter>(
              value: s,
              child: Text(
                s == _StatusFilter.all ? 'Status: All' : s.label,
                style: const TextStyle(color: _T.textDark, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Date / Period Dropdown Button (Matching Manager Theme Colors)
  Widget _buildDatePeriodDropdown() {
    final isFiltered = _datePeriod != _DatePeriod.allTime;

    String displayLabel;
    if (_datePeriod == _DatePeriod.allTime) {
      displayLabel = 'Period: All Time';
    } else if (_datePeriod == _DatePeriod.customRange) {
      if (_customStartDate != null && _customEndDate != null) {
        displayLabel =
            '${DateFormat('MMM d').format(_customStartDate!)} - ${DateFormat('MMM d').format(_customEndDate!)}';
      } else {
        displayLabel = 'Custom Range';
      }
    } else {
      displayLabel = _datePeriod.label;
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFiltered ? _T.primary : Colors.grey.shade300,
          width: isFiltered ? 1.4 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DatePeriod>(
          value: _datePeriod,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: _T.dark,
            size: 22,
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _T.textDark,
          ),
          selectedItemBuilder: (context) {
            return _DatePeriod.values.map((p) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  displayLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _T.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _datePeriod = val;
                if (val == _DatePeriod.customRange) {
                  final now = DateTime.now();
                  _customStartDate ??= DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
                  _customEndDate ??= DateTime(now.year, now.month, now.day);
                }
              });
            }
          },
          items: _DatePeriod.values.map((p) {
            return DropdownMenuItem<_DatePeriod>(
              value: p,
              child: Text(
                p.label,
                style: const TextStyle(color: _T.textDark, fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Clear Button (Matching Manager Theme Colors)
  Widget _buildClearButton() {
    final active = _hasActiveFilters;

    return InkWell(
      onTap: active ? _resetAllFilters : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? _T.light : const Color(0xFFF1F5F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? _T.primary : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 14,
              color: active ? _T.dark : Colors.grey.shade400,
            ),
            const SizedBox(width: 3),
            Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? _T.dark : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary Section
  Widget _buildSummarySection(int totalCount, List<CollectionRequest> filtered) {
    final totalKg = filtered.fold<double>(0.0, (sum, r) => sum + r.estimatedQuantity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: _T.bg,
        border: Border(bottom: BorderSide(color: _T.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _hasActiveFilters
                ? 'Showing ${filtered.length} of $totalCount requests'
                : 'Showing all $totalCount requests',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _T.textMid,
            ),
          ),
          if (totalKg > 0)
            Text(
              'Total: ${totalKg.toStringAsFixed(1)} kg',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _T.dark,
              ),
            ),
        ],
      ),
    );
  }

  // ── Requests List View (Passes filtered results directly to existing cards)
  Widget _buildRequestsList(List<CollectionRequest> requests, ManagerProvider provider) {
    return RefreshIndicator(
      color: _T.primary,
      onRefresh: () async => _refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        itemCount: requests.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == requests.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: _T.primary)),
            );
          }
          // The existing RequestCard receives the filtered results exactly as it is
          return _RequestCard(request: requests[i], onAction: _refresh);
        },
      ),
    );
  }

  Widget _buildErrorView(ManagerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'Failed to load requests',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(bool hasOtherRequests) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _T.light,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.inbox_rounded, size: 32, color: _T.primary),
            ),
            const SizedBox(height: 14),
            Text(
              _hasActiveFilters ? 'No matching requests found' : 'No collection requests yet',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _T.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _hasActiveFilters
                  ? 'Try changing your status or date filters, or clear all filters.'
                  : 'Submitted collection requests will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _T.textMid),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _T.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _resetAllFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: _T.primary),
                label: const Text('Clear All Filters', style: TextStyle(color: _T.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXISTING REQUEST CARD (COMPLETELY UNCHANGED AS REQUIRED)
// ─────────────────────────────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final CollectionRequest request;
  final VoidCallback onAction;

  const _RequestCard({required this.request, required this.onAction});

  bool get _isPending   => request.status == 'requested';
  bool get _isScheduled => request.status == 'scheduled' || request.status == 'accepted';
  bool get _isCollected => request.status == 'collected';
  bool get _isCancelled => request.status == 'cancelled';
  bool get _isDone      => _isCollected || _isCancelled;

  _StatusItem get _statusItem => _StatusItem.forStatus(request.status);

  bool get _isSpecial =>
      request.estimatedQuantity >= 10.0 ||
      request.wasteType == 'electronic' ||
      request.wasteType == 'hazardous';

  void _goDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id)),
    ).then((_) => onAction());
  }

  void _goAssign(BuildContext context) {
    final provider = context.read<ManagerProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManagerAssignmentScreen(request: request)),
    ).then((assigned) {
      if (assigned == true) {
        onAction();
        provider.fetchAvailableDrivers();
        provider.fetchDashboardStats();
        provider.fetchRoutes();
      }
    });
  }

  void _goMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManagerRequestMapScreen(request: request)),
    );
  }

  bool _isYesterdayPending() {
    if (request.status != 'requested') return false;
    final reqDate = request.preferredDate ?? request.createdAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(reqDate.year, reqDate.month, reqDate.day);
    return d == yesterday;
  }

  @override
  Widget build(BuildContext context) {
    final item = _statusItem;
    final isYestPending = _isYesterdayPending();

    return GestureDetector(
      onTap: () => _goDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isYestPending
                ? Colors.orange.shade400
                : _isDone
                    ? _T.border
                    : item.color.withValues(alpha: 0.18),
            width: isYestPending ? 1.5 : 1.0,
          ),
          boxShadow: _isDone
              ? []
              : [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                  const BoxShadow(
                    color: _T.shadow,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Line
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isYestPending
                      ? const Color(0xFFE65100)
                      : _isDone
                          ? _T.border
                          : item.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              // Main Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Waste Icon + Resident Name & Waste Type + Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _isDone ? Colors.grey.shade100 : item.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              CollectionRequest.getWasteTypeIcon(request.wasteType),
                              size: 19,
                              color: _isDone ? _T.textLight : item.color,
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name + Waste Type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.requester?.name ??
                                      (request.requesterName.isNotEmpty
                                          ? request.requesterName
                                          : 'Unknown Resident'),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isDone ? _T.textMid : _T.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      request.wasteTypeLabel,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: _T.textMid,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_isSpecial && !_isDone) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF9C4),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: const Color(0xFFFFD600)),
                                        ),
                                        child: const Text(
                                          'Special',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5D4037),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isDone ? Colors.grey.shade100 : item.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isDone ? _T.border : item.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 11,
                                  color: _isDone ? _T.textLight : item.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _StatusItem.labelForStatus(request.status),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isDone ? _T.textLight : item.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Location, Date, and Weight Info Pills
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        children: [
                          _InfoPill(
                            icon: Icons.location_on_outlined,
                            text: request.location,
                            maxWidth: 170,
                          ),
                          _buildDatePill(),
                          if (request.estimatedQuantity > 0)
                            _InfoPill(
                              icon: Icons.scale_outlined,
                              text: '${request.estimatedQuantity} kg',
                              highlight: _isSpecial && !_isDone,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Driver Row
                      Row(
                        children: [
                          Icon(
                            request.assignedDriver != null
                                ? Icons.local_shipping_outlined
                                : Icons.person_search_rounded,
                            size: 13.5,
                            color: request.assignedDriver != null
                                ? _T.dark
                                : _isPending
                                    ? const Color(0xFFE65100)
                                    : _T.textLight,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              request.assignedDriver != null
                                  ? 'Driver: ${request.assignedDriver!.name}'
                                  : _isPending
                                      ? 'No driver assigned yet'
                                      : 'Driver not assigned',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: request.assignedDriver != null
                                    ? _T.dark
                                    : _isPending
                                        ? const Color(0xFFE65100)
                                        : _T.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: _T.border),
                      const SizedBox(height: 9),

                      // Action Row (Strictly Logical)
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePill() {
    final reqDate = request.preferredDate ?? request.createdAt;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(reqDate.year, reqDate.month, reqDate.day);

    String text;
    bool highlight = false;

    if (d == today) {
      text = 'Today${request.preferredTime != null ? ' (${request.preferredTime})' : ''}';
      highlight = true;
    } else if (d == yesterday) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMM d, yyyy').format(reqDate);
    }

    return _InfoPill(
      icon: Icons.calendar_today_outlined,
      text: text,
      highlight: highlight,
    );
  }

  Widget _buildActions(BuildContext context) {
    // 1. COLLECTED — View only (green), NO reassign
    if (_isCollected) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _goDetail(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF2E7D32)),
                    SizedBox(width: 5),
                    Text(
                      'View Collected',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 2. CANCELLED — View details only, NO reassign
    if (_isCancelled) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _goDetail(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 12),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: _T.textMid),
                    SizedBox(width: 5),
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _T.textMid,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 3. SCHEDULED — View Details + Map
    if (_isScheduled) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _goDetail(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 12),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _T.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: _T.primary),
                    SizedBox(width: 5),
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _T.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: () => _goMap(context),
            child: Container(
              width: 36,
              height: 33,
              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.border),
              ),
              child: const Icon(Icons.map_outlined, size: 16, color: _T.dark),
            ),
          ),
        ],
      );
    }

    // 4. PENDING (Requested) — Map icon + Assign Route button
    final isYestPending = _isYesterdayPending();

    return Row(
      children: [
        GestureDetector(
          onTap: () => _goMap(context),
          child: Container(
            width: 36,
            height: 33,
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _T.border),
            ),
            child: const Icon(Icons.map_outlined, size: 16, color: _T.dark),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: GestureDetector(
            onTap: () => _goAssign(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 12),
              decoration: BoxDecoration(
                color: isYestPending ? const Color(0xFFE65100) : _T.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isYestPending ? Icons.priority_high_rounded : Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isYestPending
                          ? 'Assign (Missed Yesterday)'
                          : _isSpecial
                              ? 'Assign (Special)'
                              : 'Assign Route',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXISTING INFO PILL WIDGET (COMPLETELY UNCHANGED AS REQUIRED)
// ─────────────────────────────────────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  final double? maxWidth;

  const _InfoPill({
    required this.icon,
    required this.text,
    this.highlight = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: highlight ? _T.light.withValues(alpha: 0.6) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: highlight ? _T.primary.withValues(alpha: 0.2) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: highlight ? _T.dark : _T.textMid),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10.5,
                  color: highlight ? _T.dark : _T.textMid,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
