const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  getAnnouncements,
  createAnnouncement,
  deleteAnnouncement,
} = require('../controllers/announcementController');

const router = express.Router();

router.get('/', protect, getAnnouncements);
router.post('/', protect, createAnnouncement);
router.delete('/:id', protect, deleteAnnouncement);

module.exports = router;
