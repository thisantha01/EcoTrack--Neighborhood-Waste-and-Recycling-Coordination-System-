const express = require('express');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const {
  getCollectionRequests,
  getRequestDetails,
  getAvailableDrivers,
  assignDriver,
} = require('../controllers/managerController');

const router = express.Router();

// All routes require authentication and recycling_manager role
router.use(protect, authorizeRoles('recycling_manager'));

// View collection requests (with filtering)
router.get('/collection-requests', getCollectionRequests);

// View single request details
router.get('/collection-requests/:requestId', getRequestDetails);

// View available drivers
router.get('/drivers/available', getAvailableDrivers);

// Assign driver to request
router.post(
  '/collection-requests/:requestId/assign-driver',
  assignDriver
);

module.exports = router;
