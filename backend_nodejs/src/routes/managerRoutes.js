const express = require('express');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const {
  getDashboardStats,
  getCollectionRequests,
  getRequestDetails,
  getAvailableDrivers,
  assignDriver,
  getDriverLiveLocation,
  getWasteWeighIns,
  getReceivedWaste,
  updateWasteProcessing,
  getWasteReports,
} = require('../controllers/managerController');

const router = express.Router();

// All routes require authentication and recycling_manager role
router.use(protect, authorizeRoles('recycling_manager'));

// Dashboard statistics
router.get('/dashboard-stats', getDashboardStats);

// View collection requests (with filtering)
router.get('/collection-requests', getCollectionRequests);

// View single request details
router.get('/collection-requests/:requestId', getRequestDetails);

// View available drivers
router.get('/drivers/available', getAvailableDrivers);
router.get('/drivers/:driverId/location', getDriverLiveLocation);

// Assign driver to request
router.post(
  '/collection-requests/:requestId/assign-driver',
  assignDriver
);

// =====================================================
// WASTE MANAGEMENT
// =====================================================
router.get('/waste/weigh-ins', getWasteWeighIns);
router.get('/waste/received', getReceivedWaste);
router.patch('/waste/requests/:requestId/processing', updateWasteProcessing);
router.get('/waste/reports', getWasteReports);

module.exports = router;
