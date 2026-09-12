import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../providers/driver_provider.dart';

class PickupDetailScreen extends StatefulWidget {
  final PickupModel pickup;

  const PickupDetailScreen({super.key, required this.pickup});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  final List<Map<String, String>> _statusSteps = const [
    {'key': 'scheduled', 'label': 'Scheduled'},
    {'key': 'accepted', 'label': 'Accepted'},
    {'key': 'en_route', 'label': 'En Route'},
    {'key': 'arrived', 'label': 'Arrived'},
    {'key': 'completed', 'label': 'Collected'},
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.pickup.status;
  }

  int get _currentStepIndex {
    final index = _statusSteps.indexWhere((s) => s['key'] == _currentStatus);
    return index == -1 ? 0 : index;
  }

  String _getNextButtonLabel() {
    switch (_currentStatus) {
      case 'scheduled':
        return 'Accept Pickup';
      case 'accepted':
        return 'Start Route';
      case 'en_route':
        return 'Mark Arrived';
      case 'arrived':
        return 'Complete Pickup';
      default:
        return 'Completed';
    }
  }

  String _getNextStatusKey() {
    switch (_currentStatus) {
      case 'scheduled':
        return 'accepted';
      case 'accepted':
        return 'en_route';
      case 'en_route':
        return 'arrived';
      case 'arrived':
        return 'completed';
      default:
        return 'completed';
    }
  }

  Future<void> _handleStatusUpdate() async {
    final nextStatus = _getNextStatusKey();
    setState(() => _isUpdating = true);

    final success = await context.read<DriverProvider>().updatePickupStatus(
          widget.pickup.id,
          nextStatus,
        );

    setState(() => _isUpdating = false);

    if (success) {
      setState(() => _currentStatus = nextStatus);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update pickup status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F2E1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pickup #${widget.pickup.pickupNumber}',
          style: const TextStyle(
            color: Color(0xFF0F2E1D),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF0F2E1D)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E1D),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_outlined, color: Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pickup.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E1D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pickup.address,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.pickup.customerPhone != null)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    Text(
                      widget.pickup.customerPhone!,
                      style: const TextStyle(color: Color(0xFF0F2E1D), fontSize: 15),
                    ),
                  ],
                ),
              const SizedBox(height: 28),
              const Text(
                'Waste Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E1D),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.recycling, color: Color(0xFF64748B), size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.pickup.wasteType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2E1D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.pickup.weightKg} kg',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.pickup.scheduledTime,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _statusSteps.length,
                        itemBuilder: (context, index) {
                          final step = _statusSteps[index];
                          final isPassed = index < _currentStepIndex;
                          final isCurrent = index == _currentStepIndex;

                          return Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPassed
                                          ? const Color(0xFF2E7D32)
                                          : isCurrent
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFE2E8F0),
                                    ),
                                    child: Icon(
                                      isPassed ? Icons.check : Icons.circle,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (index != _statusSteps.length - 1)
                                    Container(
                                      width: 2,
                                      height: 32,
                                      color: isPassed ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                step['label']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCurrent
                                      ? const Color(0xFF2E7D32)
                                      : isPassed
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentStatus != 'completed')
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E7E43),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isUpdating ? null : _handleStatusUpdate,
                    child: _isUpdating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _getNextButtonLabel(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}