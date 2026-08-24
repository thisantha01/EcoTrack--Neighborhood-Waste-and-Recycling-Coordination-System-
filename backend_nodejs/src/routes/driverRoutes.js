const express = require('express');
const router = express.Router();
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const {
  getDashboardOverview,
  getTodaySchedule,
  updateAvailability,
  updatePickupStatus,
} = require('../controllers/driverController');

router.use(protect);
router.use(authorizeRoles('driver'));

router.get('/dashboard', getDashboardOverview);
router.get('/schedule/today', getTodaySchedule);
router.patch('/availability', updateAvailability);
router.patch('/pickups/:id/status', updatePickupStatus);

module.exports = router;