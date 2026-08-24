import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../community/community_hub_screen.dart';
import '../community/community_feed_screen.dart';
import '../community/cleanup_events_screen.dart';
import '../community/neighbourhood_screen.dart';
import '../community/engagement_screen.dart';
import '../profile/profile_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  void _goToCommunity() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _DriverHome(onGoToCommunity: _goToCommunity),
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
        indicatorColor: const Color(0xFFE3F2FD),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1565C0)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF1565C0)),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1565C0)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DriverHome extends StatelessWidget {
  final VoidCallback onGoToCommunity;

  const _DriverHome({required this.onGoToCommunity});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
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
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Driver 🚛',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Driver',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user?.vehicleType?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Vehicle: ${user!.vehicleType}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
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
                _card(
                  context,
                  Icons.dynamic_feed,
                  'Community\nFeed',
                  const Color(0xFF2E7D32),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CommunityFeedScreen())),
                ),
                _card(
                  context,
                  Icons.cleaning_services,
                  'Cleanup\nEvents',
                  const Color(0xFF1565C0),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CleanupEventsScreen())),
                ),
                _card(
                  context,
                  Icons.campaign,
                  'Announcements',
                  const Color(0xFF6A1B9A),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NeighbourhoodScreen())),
                ),
                _card(
                  context,
                  Icons.emoji_events,
                  'My\nRewards',
                  const Color(0xFFE65100),
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EngagementScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
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