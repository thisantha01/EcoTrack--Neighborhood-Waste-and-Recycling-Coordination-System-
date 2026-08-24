import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/manager_provider.dart';

class AssignDriverScreen extends StatefulWidget {
  final String requestId;
  final String requestWasteType;
  final String requestLocation;

  const AssignDriverScreen({
    super.key,
    required this.requestId,
    required this.requestWasteType,
    required this.requestLocation,
  });

  @override
  State<AssignDriverScreen> createState() =>
      _AssignDriverScreenState();
}

class _AssignDriverScreenState
    extends State<AssignDriverScreen> {
  String? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerProvider>().fetchAvailableDrivers();
    });
  }

  void _assignDriver() async {
    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a driver'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = context.read<ManagerProvider>();

    final success = await provider.assignDriver(
      requestId: widget.requestId,
      driverId: _selectedDriverId!,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                provider.error ?? 'Failed to assign driver'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Assign Driver',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Request summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6A1B9A)
                    .withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigning driver for:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.category,
                        size: 16,
                        color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 6),
                    Text(
                      widget.requestWasteType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16,
                        color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.requestLocation,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Available Drivers header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Drivers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<ManagerProvider>()
                        .fetchAvailableDrivers();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Driver list
          Expanded(
            child: Consumer<ManagerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingDrivers) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6A1B9A),
                    ),
                  );
                }

                if (provider.error != null &&
                    provider.availableDrivers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48,
                              color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton
                                .styleFrom(
                              backgroundColor:
                                  const Color(0xFF6A1B9A),
                              foregroundColor:
                                  Colors.white,
                            ),
                            onPressed: () => provider
                                .fetchAvailableDrivers(),
                            child:
                                const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider
                    .availableDrivers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 64,
                          color:
                              Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No drivers available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All drivers may be busy or unverified',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: provider
                      .availableDrivers.length,
                  itemBuilder: (context, index) {
                    final driver =
                        provider.availableDrivers[index];
                    final driverId =
                        driver['driverId']?.toString() ??
                            '';
                    final name =
                        driver['name'] ?? 'Unknown';
                    final phone =
                        driver['phone'] ?? '';
                    final vehicleType =
                        driver['vehicleType'] ?? '';
                    final availability =
                        driver['availability'] ??
                            'unknown';
                    final activePickups =
                        driver['currentAssignedPickups'] ??
                            0;
                    final isAvailable =
                        availability == 'available';
                    final isSelected =
                        _selectedDriverId == driverId;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () {
                              setState(() {
                                _selectedDriverId =
                                    isSelected
                                        ? null
                                        : driverId;
                              });
                            }
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 10),
                        padding:
                            const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6A1B9A)
                                  .withOpacity(0.08)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(
                                    0xFF6A1B9A)
                                : isAvailable
                                    ? Colors
                                        .grey.shade200
                                    : Colors
                                        .grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Selection indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(
                                        0xFF6A1B9A)
                                    : Colors
                                        .grey.shade200,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(
                                          0xFF6A1B9A)
                                      : Colors
                                          .grey.shade400,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color:
                                          Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Driver avatar
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isAvailable
                                  ? const Color(
                                          0xFF6A1B9A)
                                      .withOpacity(0.1)
                                  : Colors
                                      .grey.shade200,
                              child: Icon(
                                Icons.person,
                                color: isAvailable
                                    ? const Color(
                                        0xFF6A1B9A)
                                    : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Driver info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    name,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 2),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors
                                            .grey
                                            .shade600,
                                      ),
                                    ),
                                  if (vehicleType
                                      .isNotEmpty)
                                    Text(
                                      vehicleType,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors
                                            .grey
                                            .shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Availability badge
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: isAvailable
                                        ? Colors
                                            .green
                                            .shade50
                                        : Colors
                                            .orange
                                            .shade50,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                6),
                                  ),
                                  child: Text(
                                    isAvailable
                                        ? 'Available'
                                        : 'Busy',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: isAvailable
                                          ? Colors
                                              .green
                                              .shade700
                                          : Colors
                                              .orange
                                              .shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    height: 4),
                                Text(
                                  '$activePickups active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors
                                        .grey
                                        .shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Assign button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Consumer<ManagerProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedDriverId != null
                              ? const Color(0xFF6A1B9A)
                              : Colors.grey.shade300,
                      foregroundColor:
                          _selectedDriverId != null
                              ? Colors.white
                              : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _selectedDriverId != null &&
                                !provider.isAssigning
                            ? _assignDriver
                            : null,
                    child: provider.isAssigning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Assign Selected Driver',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
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
