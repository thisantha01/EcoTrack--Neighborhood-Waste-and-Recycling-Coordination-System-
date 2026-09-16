const express = require('express');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const router = express.Router();
const {
	createRoute,
	getRoutes,
	getRoute,
	addStop,
	removeStop,
	confirmRequestRoute,
	changeDriver,
	suggestRoute,
} = require('../controllers/routeController');

router.use(protect, authorizeRoles('recycling_manager'));

router.post('/', createRoute);
router.get('/', getRoutes);
router.get('/suggest-route', suggestRoute);
router.get('/:id', getRoute);
router.patch('/:id/change-driver', changeDriver);
router.patch('/:id/add-stop', addStop);
router.patch('/:id/remove-stop', removeStop);
router.patch('/:id/confirm-request', confirmRequestRoute);

module.exports = router;