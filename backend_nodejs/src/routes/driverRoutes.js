const express = require('express');
const router = express.Router();
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const {
  getDashboardOverview,
  getAssignedRoutes,
  getTodaySchedule,
  updateLiveLocation,
  updateAssignedRouteStopStatus,
  endAssignedRoute,
  resetAssignedRoute,
  updateAvailability,
  updatePickupStatus,
  updatePickupDetails,
  createWasteWeighIn,
} = require('../controllers/driverController');

router.use(protect);
router.use(authorizeRoles('driver'));

router.get('/dashboard', getDashboardOverview);
router.get('/routes', getAssignedRoutes);
router.get('/schedule/today', getTodaySchedule);
router.post('/location', updateLiveLocation);
router.patch('/routes/:routeId/stops/:stopId/status', updateAssignedRouteStopStatus);
router.patch('/routes/:routeId/end', endAssignedRoute);
router.patch('/routes/:routeId/reset', resetAssignedRoute);
router.patch('/availability', updateAvailability);
router.patch('/pickups/:id/status', updatePickupStatus);
router.patch('/pickups/:id/details', updatePickupDetails);
router.post('/weigh-ins', createWasteWeighIn);

module.exports = router;
