const UserPoints = require('../models/UserPoints');
const User = require('../models/User');


// =====================================================
// GET MY POINTS / PROFILE
// =====================================================

const getMyEngagement = async (req, res) => {
  try {
    let userPoints = await UserPoints.findOne({ user: req.user._id });

    if (!userPoints) {
      userPoints = await UserPoints.create({
        user: req.user._id,
        points: 0,
        level: 'bronze',
      });
    }

    return res.status(200).json({
      success: true,
      engagement: userPoints,
    });

  } catch (error) {
    console.error('Get engagement error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch engagement data',
    });
  }
};


// =====================================================
// LEADERBOARD
// =====================================================

const getLeaderboard = async (req, res) => {
  try {
    const leaderboard = await UserPoints.find()
      .sort({ points: -1 })
      .limit(20)
      .populate('user', 'name profilePicture role');

    return res.status(200).json({
      success: true,
      leaderboard,
    });

  } catch (error) {
    console.error('Leaderboard error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch leaderboard',
    });
  }
};


// =====================================================
// COMMUNITY STATS
// =====================================================

const getCommunityStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ isVerified: true });

    const pointsAggregate = await UserPoints.aggregate([
      {
        $group: {
          _id: null,
          totalWasteCollected: { $sum: '$totalWasteCollected' },
          totalEventsJoined: { $sum: '$eventsJoined' },
          totalReports: { $sum: '$reportsSubmitted' },
        },
      },
    ]);

    const stats = pointsAggregate[0] || {
      totalWasteCollected: 0,
      totalEventsJoined: 0,
      totalReports: 0,
    };

    return res.status(200).json({
      success: true,
      stats: {
        totalUsers,
        totalWasteCollected: stats.totalWasteCollected,
        totalEventsJoined: stats.totalEventsJoined,
        totalReports: stats.totalReports,
      },
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch community stats',
    });
  }
};


// =====================================================
// AWARD BADGE (internal helper, also exposed)
// =====================================================

const checkAndAwardBadges = async (userId) => {
  try {
    const userPoints = await UserPoints.findOne({ user: userId });
    if (!userPoints) return;

    const existingBadges = userPoints.badges.map((b) => b.name);
    const newBadges = [];

    const badgeDefs = [
      { name: 'First Post', condition: userPoints.postsCreated >= 1, icon: '📝', description: 'Created your first community post' },
      { name: 'Active Member', condition: userPoints.postsCreated >= 10, icon: '🌟', description: 'Created 10 community posts' },
      { name: 'First Cleanup', condition: userPoints.eventsJoined >= 1, icon: '🌱', description: 'Joined your first cleanup event' },
      { name: 'Cleanup Hero', condition: userPoints.eventsJoined >= 5, icon: '🦸', description: 'Joined 5 cleanup events' },
      { name: 'Reporter', condition: userPoints.reportsSubmitted >= 1, icon: '📢', description: 'Submitted your first report' },
      { name: 'Point Milestone', condition: userPoints.points >= 100, icon: '🏅', description: 'Earned 100 points' },
      { name: 'Eco Champion', condition: userPoints.points >= 500, icon: '🏆', description: 'Earned 500 points' },
    ];

    for (const badge of badgeDefs) {
      if (badge.condition && !existingBadges.includes(badge.name)) {
        newBadges.push({
          name: badge.name,
          description: badge.description,
          icon: badge.icon,
        });
      }
    }

    if (newBadges.length > 0) {
      await UserPoints.findOneAndUpdate(
        { user: userId },
        { $push: { badges: { $each: newBadges } } }
      );
    }
  } catch (err) {
    console.error('Badge check error:', err);
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getMyEngagement,
  getLeaderboard,
  getCommunityStats,
  checkAndAwardBadges,
};
