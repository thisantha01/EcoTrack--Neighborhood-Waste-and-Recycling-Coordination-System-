import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manager_provider.dart';
import '../profile/profile_screen.dart';
import 'collection_requests_screen.dart';
import 'manager_inventory_screen.dart';
import 'manager_routes_screen.dart';
import 'manager_waste_screen.dart';

class RecyclingManagerDashboard extends StatefulWidget {
  const RecyclingManagerDashboard({super.key});

  @override
  State<RecyclingManagerDashboard> createState() =>
      _RecyclingManagerDashboardState();
}

class _RecyclingManagerDashboardState
    extends State<RecyclingManagerDashboard> {
  int _selectedIndex = 0;

  void _goToAssignRoute() => setState(() => _selectedIndex = 2);
  void _goToCollectionRequests() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _RecyclingManagerHome(
        onGoToAssignRoute: _goToAssignRoute,
        onGoToCollectionRequests: _goToCollectionRequests,
      ),
      const CollectionRequestsScreen(),
      const ManagerRoutesScreen(),
      const ManagerWasteScreen(),
      const ManagerInventoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color(0xFFDDF7F8),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF0097A7)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox, color: Color(0xFF0097A7)),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route, color: Color(0xFF0097A7)),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete, color: Color(0xFF0097A7)),
            label: 'Waste',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF0097A7)),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF0097A7)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _RecyclingManagerHome extends StatefulWidget {
  final VoidCallback onGoToAssignRoute;
  final VoidCallback onGoToCollectionRequests;

  const _RecyclingManagerHome({
    required this.onGoToAssignRoute,
    required this.onGoToCollectionRequests,
  });

  @override
  State<_RecyclingManagerHome> createState() => _RecyclingManagerHomeState();
}

class _RecyclingManagerHomeState extends State<_RecyclingManagerHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ManagerProvider>();
        provider.fetchDashboardStats();
        provider.fetchRoutes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final managerProvider = context.watch<ManagerProvider>();
    final isLoadingStats = managerProvider.isLoadingDashboardStats;
    final stats = managerProvider.dashboardStat;
    final assignedRoutes = managerProvider.routes;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EcoTrack',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Recycling center manager',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (r) => false);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manager Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF008C99), Color(0xFF00B8B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome back,',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              user?.name ?? 'Recycling Manager',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                                radius: 3, backgroundColor: Colors.greenAccent),
                            SizedBox(width: 4),
                            Text('Active',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onGoToCollectionRequests,
                          icon: const Icon(Icons.inbox, size: 16),
                          label: const Text('View Requests',
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6A1B9A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onGoToAssignRoute,
                          icon: const Icon(Icons.add_location_alt,
                              color: Colors.white, size: 16),
                          label: const Text('Assign Route',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Operations Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Fixed Height Stat Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _statCard(
                  title: 'Accepted Requests',
                  value: isLoadingStats
                      ? '...'
                      : '${stats('acceptedRequests')} Total',
                  icon: Icons.alt_route,
                  color: const Color(0xFF1565C0),
                  subtitle: isLoadingStats ? 'Loading...' : 'Ready for scheduling',
                ),
                _statCard(
                  title: 'Completed Requests',
                  value: isLoadingStats
                      ? '...'
                      : '${stats('completedRequests')} Requests',
                  icon: Icons.recycling,
                  color: const Color(0xFF2E7D32),
                  subtitle: isLoadingStats
                      ? 'Loading...'
                      : '${stats('todayRequestsCount')} received today',
                ),
                _statCard(
                  title: 'Pending Requests',
                  value: isLoadingStats
                      ? '...'
                      : '${stats('pendingRequests')} Requests',
                  icon: Icons.report_problem_outlined,
                  color: const Color(0xFFD32F2F),
                  subtitle: isLoadingStats ? 'Loading...' : 'Requires action',
                ),
                _statCard(
                  title: 'Active Drivers',
                  value: isLoadingStats
                      ? '...'
                      : '${stats('totalDriversCount')} Total',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFE65100),
                  subtitle: isLoadingStats
                      ? 'Loading...'
                      : '${stats('busyDriversCount')} currently busy',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Assigned Routes Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Assigned Routes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: widget.onGoToAssignRoute,
                  child: const Text('Create New',
                      style: TextStyle(color: Color(0xFF6A1B9A))),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Assigned Routes List
            assignedRoutes.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('No routes assigned yet.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assignedRoutes.length,
                    itemBuilder: (context, index) {
                      final route = assignedRoutes[index];
                      final driver = route['assignedDriver'];
                      final status = route['status']?.toString() ?? 'draft';
                      final statusColor = status == 'completed'
                          ? Colors.green
                          : status == 'in-progress'
                              ? Colors.orange
                              : Colors.blue;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.alt_route,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route['zone']?.toString() ?? 'Unassigned area',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${driver is Map ? driver['name'] ?? 'Unassigned' : 'Unassigned'}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}