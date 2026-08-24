const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  createRequest,
  getMyRequests,
  getAllRequests,
  getRequest,
  updateStatus,
  cancelRequest,
} = require('../controllers/collectionRequestController');

// All routes require authentication
router.use(protect);

// CRUD
router.post('/', createRequest);
router.get('/my', getMyRequests);
router.get('/all', getAllRequests);
router.get('/:id', getRequest);
router.put('/:id/status', updateStatus);
router.put('/:id/cancel', cancelRequest);

module.exports = router;
