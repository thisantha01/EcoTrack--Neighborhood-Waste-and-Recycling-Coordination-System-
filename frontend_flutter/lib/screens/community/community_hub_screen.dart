import 'package:flutter/material.dart';
import 'community_feed_screen.dart';
import 'cleanup_events_screen.dart';
import 'neighbourhood_screen.dart';
import 'engagement_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CommunityFeedScreen(),
    const CleanupEventsScreen(),
    const NeighbourhoodScreen(),
    const EngagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              );
            }
            return const TextStyle(fontSize: 11, color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: const Color(0xFFE8F5E9),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed, color: Color(0xFF2E7D32)),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.cleaning_services_outlined),
              selectedIcon: Icon(Icons.cleaning_services, color: Color(0xFF2E7D32)),
              label: 'Cleanup',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups, color: Color(0xFF2E7D32)),
              label: 'Neighbours',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events, color: Color(0xFF2E7D32)),
              label: 'Rewards',
            ),
          ],
        ),
      ),
    );
  }
}
