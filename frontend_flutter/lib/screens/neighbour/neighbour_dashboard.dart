import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../community/community_hub_screen.dart';
import '../community/community_feed_screen.dart';
import '../community/cleanup_events_screen.dart';
import '../community/community_reports_screen.dart';
import '../community/my_requests_screen.dart';
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
  void _goToCommunity() => setState(() => _selectedIndex = 3);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _NeighbourHome(onGoToCommunity: _goToCommunity),
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
        surfaceTintColor: Colors.white,          indicatorColor: const Color(0xFFE8F5E9),
          destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF2E7D32)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report, color: Color(0xFF2E7D32)),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete, color: Color(0xFF2E7D32)),
            label: 'Requests',
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

            const SizedBox(height: 16),

            // ── Today's Waste Collection Schedule Card ─────
            const _WasteCollectionNoticeCard(),

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

// ─────────────────────────────────────────────────────────
// Today's Waste Collection Notice & Schedule Card
// ─────────────────────────────────────────────────────────
class _WasteCollectionNoticeCard extends StatelessWidget {
  const _WasteCollectionNoticeCard();

  void _showWeeklyScheduleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text(
                      'Weekly Waste Schedule',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Text(
              'Neighborhood Waste & Recycling Coordination Schedule',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _scheduleRow('Monday', '🥬 Organic Waste', 'Roadside collection 7:00 AM. Afternoon: Special requests', const Color(0xFF2E7D32)),
            _scheduleRow('Tuesday', '⭐ Special Requests', 'All day dedicated to on-demand special collection requests', const Color(0xFFB45309)),
            _scheduleRow('Wednesday', '🧴📦 Plastic & Paper', 'Bottles, clean plastics, cartons, paper. Afternoon: Special requests', const Color(0xFF0288D1)),
            _scheduleRow('Thursday', '⭐ Special Requests', 'All day dedicated to on-demand special collection requests', const Color(0xFFB45309)),
            _scheduleRow('Friday', '🍾 Glass & Others', 'Glass bottles, metal cans, recyclable items. Afternoon: Special requests', const Color(0xFF6A1B9A)),
            _scheduleRow('Saturday', '📦 Weekend Requests', 'On-demand special pickups & bulk recyclable collection', const Color(0xFFA21CAF)),
            _scheduleRow('Sunday', '🛑 Fleet Maintenance', 'Routine vehicle servicing. Emergency/advance requests only.', Colors.grey.shade600),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _scheduleRow(String day, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekdayIndex = DateTime.now().weekday - 1;
    final todayName = days[weekdayIndex];

    String icon;
    String title;
    String advice;
    Color bg;
    Color border;
    Color fg;

    switch (todayName) {
      case 'Tuesday':
      case 'Thursday':
        icon = '⭐';
        title = 'Special Requests Day (විශේෂ ඉල්ලීම් දිනය)';
        advice = 'No roadside bin truck today. Today is dedicated to on-demand special collection requests. Schedule a pickup under "Requests".';
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        fg = const Color(0xFFB45309);
        break;
      case 'Wednesday':
        icon = '🧴📦';
        title = 'Plastic & Paper (ප්ලාස්ටික් සහ කඩදාසි)';
        advice = 'Clean plastic bottles, wrappers, flattened cartons, and paper bundles outside by 7:00 AM. Special requests handled after route completion.';
        bg = const Color(0xFFF0F9FF);
        border = const Color(0xFFBAE6FD);
        fg = const Color(0xFF0288D1);
        break;
      case 'Friday':
        icon = '🍾';
        title = 'Glass & Others (වීදුරු සහ අනෙකුත් ද්‍රව්‍ය)';
        advice = 'Safely place clean glass bottles, metal cans, and dry recyclables outside by 7:00 AM. Special requests handled after route completion.';
        bg = const Color(0xFFF5F3FF);
        border = const Color(0xFFDDD6FE);
        fg = const Color(0xFF7C3AED);
        break;
      case 'Saturday':
        icon = '📦';
        title = 'Weekend Special Requests (සති අන්ත ඉල්ලීම්)';
        advice = 'On-demand weekend pickups active today. Submit your request under "Requests".';
        bg = const Color(0xFFFDF4FF);
        border = const Color(0xFFF5D0FE);
        fg = const Color(0xFFA21CAF);
        break;
      case 'Sunday':
        icon = '🛑';
        title = 'Fleet Maintenance Day (නඩත්තු දිනය)';
        advice = 'No municipal collection today. Advance bookings can be made under "Requests".';
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFCBD5E1);
        fg = const Color(0xFF475569);
        break;
      default: // Monday
        icon = '🥬';
        title = 'Organic Waste (දිරන කසළ)';
        advice = 'Place food scraps and garden waste in your green bin outside by 7:00 AM. Special requests handled after route completion.';
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFF86EFAC);
        fg = const Color(0xFF15803D);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Collection ($todayName)",
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showWeeklyScheduleModal(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Weekly',
                        style: TextStyle(
                          fontSize: 12,
                          color: fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: fg),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            advice,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}