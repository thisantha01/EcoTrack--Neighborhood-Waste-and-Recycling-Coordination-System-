import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../community/community_hub_screen.dart';
import '../community/community_feed_screen.dart';
import '../community/cleanup_events_screen.dart';
import '../community/community_reports_screen.dart';
import '../community/engagement_screen.dart';
import '../profile/profile_screen.dart';

class NeighbourDashboard extends StatefulWidget {
  const NeighbourDashboard({super.key});

  @override
  State<NeighbourDashboard> createState() => _NeighbourDashboardState();
}

class _NeighbourDashboardState extends State<NeighbourDashboard> {
  int _selectedIndex = 0;

  // We keep the hub index so the nav bar stays correct,
  // but expose a callback so Home can switch to Community tab.
  void _goToCommunity() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _NeighbourHome(onGoToCommunity: _goToCommunity),
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
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2E7D32)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF2E7D32)),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Home page (needs a callback to switch the parent's tab
// AND the ability to push full-screen community sub-pages)
// ─────────────────────────────────────────────────────────
class _NeighbourHome extends StatelessWidget {
  final VoidCallback onGoToCommunity;

  const _NeighbourHome({required this.onGoToCommunity});

  void _openFeed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityFeedScreen()),
    );
  }

  void _openCleanup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CleanupEventsScreen()),
    );
  }

  void _openReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityReportsScreen()),
    );
  }

  void _openRewards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EngagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'EcoTrack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome card ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back! 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Neighbour',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help keep your neighbourhood clean! 🌿',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  // "Go to Community" shortcut button
                  OutlinedButton.icon(
                    onPressed: onGoToCommunity,
                    icon: const Icon(Icons.people, color: Colors.white, size: 18),
                    label: const Text(
                      'Community Hub',
                      style: TextStyle(color: Colors.white),
                    ),
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

            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ── Quick Action Grid ─────────────────────────
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _QuickActionCard(
                  icon: Icons.dynamic_feed,
                  label: 'Community\nFeed',
                  color: const Color(0xFF1565C0),
                  onTap: () => _openFeed(context),
                ),
                _QuickActionCard(
                  icon: Icons.cleaning_services,
                  label: 'Cleanup\nEvents',
                  color: const Color(0xFF2E7D32),
                  onTap: () => _openCleanup(context),
                ),
                _QuickActionCard(
                  icon: Icons.report,
                  label: 'Report\nIssue',
                  color: const Color(0xFFD32F2F),
                  onTap: () => _openReports(context),
                ),
                _QuickActionCard(
                  icon: Icons.emoji_events,
                  label: 'My\nRewards',
                  color: const Color(0xFFE65100),
                  onTap: () => _openRewards(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Reusable Quick Action Card widget
// ─────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}