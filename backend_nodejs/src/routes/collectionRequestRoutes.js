const express = require('express');
const { protect } = require('../middleware/authMiddleware');
const {
  createCollectionRequest,
  getMyCollectionRequests,
  getMyCollectionRequest,
  cancelCollectionRequest,
} = require('../controllers/collectionRequestController');

const router = express.Router();

// All routes require authentication
router.use(protect);

// Create a new collection request
router.post('/', createCollectionRequest);

// Get my collection requests
router.get('/', getMyCollectionRequests);

// Get my single request
router.get('/:id', getMyCollectionRequest);

// Cancel my request
router.put('/:id/cancel', cancelCollectionRequest);

module.exports = router;
