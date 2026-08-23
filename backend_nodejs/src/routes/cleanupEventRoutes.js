const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  getEvents,
  getEvent,
  createEvent,
  toggleJoin,
  updateEventStatus,
} = require('../controllers/cleanupEventController');

const router = express.Router();

router.get('/', protect, getEvents);
router.get('/:id', protect, getEvent);
router.post('/', protect, createEvent);
router.post('/:id/join', protect, toggleJoin);
router.put('/:id/status', protect, updateEventStatus);

module.exports = router;
