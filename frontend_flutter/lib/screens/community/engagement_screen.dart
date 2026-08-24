import 'package:flutter/material.dart';
import '../../models/engagement_model.dart';
import '../../services/engagement_service.dart';

class EngagementScreen extends StatefulWidget {
  const EngagementScreen({super.key});

  @override
  State<EngagementScreen> createState() => _EngagementScreenState();
}

class _EngagementScreenState extends State<EngagementScreen>
    with SingleTickerProviderStateMixin {
  final EngagementService _service = EngagementService();
  UserEngagement? _myEngagement;
  List<LeaderboardEntry> _leaderboard = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getMyEngagement(),
        _service.getLeaderboard(),
        _service.getCommunityStats(),
      ]);
      setState(() {
        _myEngagement = results[0] as UserEngagement;
        _leaderboard = results[1] as List<LeaderboardEntry>;
        _stats = results[2] as Map<String, dynamic>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('🏆 Engagement',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Stats'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyStats(),
                _buildLeaderboard(),
                _buildCommunityStats(),
              ],
            ),
    );
  }

  Widget _buildMyStats() {
    if (_myEngagement == null) {
      return const Center(child: Text('No data available'));
    }
    final e = _myEngagement!;

    final levelColors = {
      'bronze': const Color(0xFFCD7F32),
      'silver': const Color(0xFFC0C0C0),
      'gold': const Color(0xFFFFD700),
      'platinum': const Color(0xFF6A5ACD),
    };
    final levelColor = levelColors[e.level] ?? Colors.grey;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Points card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32),
                    const Color(0xFF66BB6A)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${e.points}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text('Points',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.level.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _statCard(
                    '🌱', 'Events Joined', '${e.eventsJoined}', Colors.green),
                _statCard(
                    '📝', 'Posts Created', '${e.postsCreated}', Colors.blue),
                _statCard('🚨', 'Reports Filed', '${e.reportsSubmitted}',
                    Colors.red),
                _statCard('♻️', 'Waste Collected',
                    '${e.totalWasteCollected.toStringAsFixed(1)} kg', Colors.teal),
              ],
            ),
            const SizedBox(height: 16),
            // Badges
            if (e.badges.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Badges Earned',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: e.badges.length,
                itemBuilder: (ctx, i) {
                  final badge = e.badges[i];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(badge.icon,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 4),
                          Text(
                            badge.name,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            badge.description,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('🏅', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text(
                        'Start participating to earn badges!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String icon, String label, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏆', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('No leaderboard data yet',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    final medals = ['🥇', '🥈', '🥉'];

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _leaderboard.length,
        itemBuilder: (ctx, i) {
          final entry = _leaderboard[i];
          final levelColors = {
            'bronze': const Color(0xFFCD7F32),
            'silver': const Color(0xFFC0C0C0),
            'gold': const Color(0xFFFFD700),
            'platinum': const Color(0xFF6A5ACD),
          };
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: i < 3 ? 4 : 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: i < 3
                  ? Text(medals[i], style: const TextStyle(fontSize: 28))
                  : CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
              title: Text(
                entry.user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColors[entry.engagement.level]
                          ?.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: levelColors[entry.engagement.level] ??
                              Colors.grey),
                    ),
                    child: Text(
                      entry.engagement.level.toUpperCase(),
                      style: TextStyle(
                          color: levelColors[entry.engagement.level],
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.engagement.points} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  Text(
                    '${entry.engagement.badges.length} badges',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityStats() {
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2E7D32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Community achievement card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    '🌍 Community Achievement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _communityStatItem(
                          '${_stats['totalUsers'] ?? 0}', 'Members'),
                      _communityStatItem(
                          '${_stats['totalEventsJoined'] ?? 0}',
                          'Events Joined'),
                      _communityStatItem(
                          '${_stats['totalReports'] ?? 0}', 'Reports'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(_stats['totalWasteCollected'] as num?)?.toStringAsFixed(1) ?? 0} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total Waste Collected',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Example achievement card (as per your brief)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Latest Achievement',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text(
                      'Green Community Cleanup',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _achievementRow('👥',
                        '${_stats['totalUsers'] ?? 25} residents participated'),
                    _achievementRow('🗑️',
                        '${(_stats['totalWasteCollected'] as num?)?.toStringAsFixed(0) ?? 120} kg waste collected'),
                    _achievementRow('♻️',
                        '${((_stats['totalWasteCollected'] as num?)?.toDouble() ?? 120) * 0.625 ~/ 1} kg recycled'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _communityStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style:
              const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _achievementRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
