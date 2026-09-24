const express = require('express');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const router = express.Router();
const {
	createRoute,
	getRoutes,
	getRoute,
	updateRoute,
	deleteRoute,
	addStop,
	removeStop,
	reorderStops,
	confirmRequestRoute,
	changeDriver,
	suggestRoute,
	getPublicRouteSchedule,
	updateStopStatus,
	optimizeRouteSequence,
} = require('../controllers/routeController');

// Schedule endpoint accessible to all authenticated users (residents, drivers, managers)
router.get('/schedule', protect, getPublicRouteSchedule);

// Stop status update accessible to both drivers and recycling managers
router.patch('/:id/stops/:stopIndex/status', protect, authorizeRoles('recycling_manager', 'driver'), updateStopStatus);

router.use(protect, authorizeRoles('recycling_manager'));

router.post('/', createRoute);
router.get('/', getRoutes);
router.get('/suggest-route', suggestRoute);
router.get('/:id', getRoute);
router.put('/:id', updateRoute);
router.patch('/:id', updateRoute);
router.delete('/:id', deleteRoute);
router.patch('/:id/change-driver', changeDriver);
router.patch('/:id/add-stop', addStop);
router.patch('/:id/remove-stop', removeStop);
router.patch('/:id/reorder-stops', reorderStops);
router.put('/:id/reorder-stops', reorderStops);
router.patch('/:id/confirm-request', confirmRequestRoute);
router.patch('/:id/optimize-sequence', optimizeRouteSequence);

module.exports = router;