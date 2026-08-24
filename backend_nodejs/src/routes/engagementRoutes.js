const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  getMyEngagement,
  getLeaderboard,
  getCommunityStats,
} = require('../controllers/engagementController');

const router = express.Router();

router.get('/me', protect, getMyEngagement);
router.get('/leaderboard', protect, getLeaderboard);
router.get('/stats', protect, getCommunityStats);

module.exports = router;
