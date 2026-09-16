import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pickup_model.dart';
import '../../providers/driver_provider.dart';
import 'pickup_detail_screen.dart';

class AssignPickupScreen extends StatefulWidget {
  const AssignPickupScreen({super.key});

  @override
  State<AssignPickupScreen> createState() => _AssignPickupScreenState();
}

class _AssignPickupScreenState extends State<AssignPickupScreen> {
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color darkGreen = Color(0xFF0F2E1D);
  static const Color backgroundColor = Color(0xFFF8FAF9);

  String _selectedFilter = "All";
  final List<String> _filters = const [
    "All",
    "Pending",
    "Accepted",
    "In Progress",
    "Completed",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DriverProvider>().fetchTodaySchedule(),
    );
  }

  List<PickupModel> _filteredPickups(DriverProvider provider) {
    if (_selectedFilter == 'All') return provider.scheduleList;
    return provider.scheduleList
        .where((pickup) => _statusLabel(pickup.status) == _selectedFilter)
        .toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'en_route':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'arrived':
        return 'Arrived';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Assigned Pickups",
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: darkGreen),
            onPressed: () {
              // TODO: hook up advanced filter/sort sheet
            },
          ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, child) {
          final pickups = _filteredPickups(provider);
          if (provider.isScheduleLoading && provider.scheduleList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchTodaySchedule(),
            child: Column(
              children: [
                _buildFilterRow(),
                const SizedBox(height: 4),
                Expanded(
                  child: pickups.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                provider.errorMessage ??
                                    'No requests assigned to you',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: pickups.length,
                          itemBuilder: (context, index) {
                            return _PickupCard(pickup: pickups[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            showCheckmark: false,
            selectedColor: primaryGreen,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : primaryGreen,
              fontWeight: FontWeight.w600,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected
                    ? primaryGreen
                    : primaryGreen.withOpacity(0.4),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  final PickupModel pickup;

  const _PickupCard({required this.pickup});

  static const Color primaryGreen = _AssignPickupScreenState.primaryGreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: pickup id + time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Pickup ${pickup.pickupNumber}",
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                pickup.scheduledTime,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Address row
          _InfoRow(icon: Icons.location_on_outlined, text: pickup.address),
          const SizedBox(height: 6),

          // Waste type + weight row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _InfoRow(icon: Icons.recycling, text: pickup.wasteType),
              ),
              Text(
                '${pickup.weightKg.toInt()} kg',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status pill
          _StatusPill(status: pickup.status),
          const SizedBox(height: 14),

          // Action row — differs by status
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickupDetailScreen(pickup: pickup),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: const Text(
          "View Details",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  String get label {
    switch (status) {
      case 'en_route':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'arrived':
        return 'Arrived';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color get color {
    switch (status) {
      case 'accepted':
        return const Color(0xFFE0A429);
      case 'en_route':
      case 'arrived':
        return const Color(0xFF3C8C5C);
      case 'completed':
        return const Color(0xFF0F2E1D);
      default:
        return const Color(0xFF2E8B57);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
