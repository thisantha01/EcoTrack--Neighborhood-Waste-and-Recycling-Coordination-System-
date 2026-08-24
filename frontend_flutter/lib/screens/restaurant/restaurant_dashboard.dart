import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../community/community_hub_screen.dart';
import '../community/community_feed_screen.dart';
import '../community/cleanup_events_screen.dart';
import '../community/community_reports_screen.dart';
import '../community/my_requests_screen.dart';
import '../community/neighbourhood_screen.dart';
import '../community/engagement_screen.dart';
import '../profile/profile_screen.dart';

class RestaurantDashboard extends StatefulWidget {
  const RestaurantDashboard({super.key});

  @override
  State<RestaurantDashboard> createState() => _RestaurantDashboardState();
}

class _RestaurantDashboardState extends State<RestaurantDashboard> {
  int _selectedIndex = 0;

  void _goToCommunity() => setState(() => _selectedIndex = 3);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _RestaurantHome(onGoToCommunity: _goToCommunity),
      const CommunityReportsScreen(),
      const MyRequestsScreen(),
      const CommunityHubScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: const Color(0xFFFBE9E7),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE65100)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report, color: Color(0xFFE65100)),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete, color: Color(0xFFE65100)),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFFE65100)),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFE65100)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _RestaurantHome extends StatelessWidget {
  final VoidCallback onGoToCommunity;

  const _RestaurantHome({required this.onGoToCommunity});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Text('EcoTrack',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF8A65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Restaurant Owner 🍽️',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Owner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.restaurantName?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(user!.restaurantName!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: onGoToCommunity,
                    icon: const Icon(Icons.people,
                        color: Colors.white, size: 18),
                    label: const Text('Community Hub',
                        style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quick Actions',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildCard(
                  context,
                  Icons.dynamic_feed,
                  'Community\nFeed',
                  const Color(0xFF1565C0),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityFeedScreen()),
                  ),
                ),
                _buildCard(
                  context,
                  Icons.cleaning_services,
                  'Cleanup\nEvents',
                  const Color(0xFF2E7D32),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CleanupEventsScreen()),
                  ),
                ),
                _buildCard(
                  context,
                  Icons.campaign,
                  'Announcements',
                  const Color(0xFF6A1B9A),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NeighbourhoodScreen()),
                  ),
                ),
                _buildCard(
                  context,
                  Icons.emoji_events,
                  'My\nRewards',
                  const Color(0xFFE65100),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EngagementScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withAlpha(40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}