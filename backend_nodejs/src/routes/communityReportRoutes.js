const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  getReports,
  getReport,
  createReport,
  toggleUpvote,
  addAdditionalInfo,
  updateReportStatus,
  updateReport,
} = require('../controllers/communityReportController');

const router = express.Router();

router.get('/', protect, getReports);
router.get('/:id', protect, getReport);
router.post('/', protect, createReport);
router.post('/:id/upvote', protect, toggleUpvote);
router.post('/:id/info', protect, addAdditionalInfo);
router.put('/:id', protect, updateReport);
router.put('/:id/status', protect, updateReportStatus);

module.exports = router;
