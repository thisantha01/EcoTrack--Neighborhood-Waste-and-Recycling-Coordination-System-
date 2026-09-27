const Pickup = require('../models/pickup');
const User = require('../models/User'); 
const Route = require('../models/Route');
const CollectionRequest = require('../models/CollectionRequest');
const WasteWeighIn = require('../models/WasteWeighIn');

const getTodayRequestFilter = (driverId, startOfDay, endOfDay) => ({
  assignedDriver: driverId,
  $or: [
    { preferredDate: { $gte: startOfDay, $lte: endOfDay } },
    {
      statusHistory: {
        $elemMatch: {
          status: { $in: ['accepted', 'scheduled', 'collected'] },
          timestamp: { $gte: startOfDay, $lte: endOfDay },
        },
      },
    },
  ],
});

/**
 * @desc    Get fixed routes and collection requests assigned to the driver
 * @route   GET /api/driver/routes
 * @access  Private (Driver only)
 */
exports.getAssignedRoutes = async (req, res) => {
  try {
    const routes = await Route.find({
      assignedDriver: req.user._id,
      $or: [
        { routeStatus: 'Active' },
        { status: { $in: ['Active', 'assigned', 'in-progress', 'completed'] } },
      ],
    })
      .sort({ date: 1 })
      .populate({
        path: 'routeStops.collectionRequestId',
        populate: { path: 'requester', select: 'name phone' },
      });

    return res.status(200).json({
      success: true,
      routes,
    });
  } catch (error) {
    console.error('Get assigned routes error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch assigned routes',
    });
  }
};

/**
 * @desc    Get dashboard overview metrics and next scheduled pickup
 * @route   GET /api/driver/dashboard
 * @access  Private (Driver only)
 */
exports.getDashboardOverview = async (req, res) => {
  try {
    const driverId = req.user._id;
    const driver = await User.findById(driverId).select('name phone vehicleType isAvailable');
    if (!driver) {
      return res.status(404).json({ message: 'Driver account not found' });
    }
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const [requests, legacyPickups, routes, allRequests, allRoutes, weighIns] = await Promise.all([
      CollectionRequest.find(getTodayRequestFilter(driverId, startOfDay, endOfDay))
        .sort({ preferredTime: 1, createdAt: 1 }).populate('requester', 'name phone'),
      Pickup.find({
        driverId,
        createdAt: { $gte: startOfDay, $lte: endOfDay },
      }).sort({ scheduledTime: 1, createdAt: 1 }),
      Route.find({
        assignedDriver: driverId,
        $or: [{ routeStatus: 'Active' }, { status: { $in: ['Active', 'assigned', 'in-progress', 'completed'] } }],
      }).sort({ date: 1 }),
      CollectionRequest.find({ assignedDriver: driverId }).sort({ createdAt: -1 })
        .populate('requester', 'name phone'),
      Route.find({ assignedDriver: driverId }),
      WasteWeighIn.find({ driver: driverId }).sort({ recordedAt: -1 }).populate('route', 'routeName zone'),
    ]);

    // CollectionRequest is the current collection workflow. Pickup remains
    // supported so existing legacy records are not silently excluded.
    const todayPickups = [
      ...requests.map((request) => ({
        _id: request._id,
        pickupNumber: `REQ-${request._id.toString().slice(-6).toUpperCase()}`,
        customerName: request.requester?.name || 'Collection requester',
        customerPhone: request.requester?.phone,
        address: request.location,
        wasteType: request.wasteType,
        weightKg: request.collectedQuantity ?? request.estimatedQuantity ?? 0,
        scheduledTime: request.preferredTime || '',
        status: request.status === 'collected' ? 'completed' : request.status,
        notes: request.driverNotes || request.description,
      })),
      ...legacyPickups.map((pickup) => pickup.toObject()),
    ];

    const currentDayRoutes = routes.filter((route) => {
      if (route.status !== 'completed') return true;
      const endedAt = route.lastRunEndedAt;
      return endedAt && endedAt >= startOfDay && endedAt <= endOfDay;
    });
    const todayStops = currentDayRoutes.flatMap((route) =>
      route.routeStops?.length ? route.routeStops : route.stops || []
    );
    const completedStops = todayStops.filter((stop) => ['collected', 'skipped'].includes(stop.status));
    const collectedStops = todayStops.filter((stop) => stop.status === 'collected');
    const remainingStops = todayStops.filter((stop) => stop.status === 'pending');
    const completedPickupRecords = todayPickups.filter((pickup) =>
      ['completed', 'collected'].includes((pickup.status || '').toLowerCase())
    );
    const cancelledPickupRecords = todayPickups.filter((pickup) =>
      (pickup.status || '').toLowerCase() === 'cancelled'
    );
    const remainingPickups = todayPickups.length - completedPickupRecords.length - cancelledPickupRecords.length;
    const collectedByCategory = completedPickupRecords.reduce((totals, pickup) => {
      const category = (pickup.wasteType || 'other').toLowerCase();
      totals[category] = (totals[category] || 0) + (Number(pickup.weightKg) || 0);
      return totals;
    }, {});
    const totalCollectedWeight = completedPickupRecords.reduce(
      (total, pickup) => total + (Number(pickup.weightKg) || 0),
      0
    );
    const nextPickup = todayPickups.find((pickup) =>
      !['completed', 'collected', 'cancelled'].includes((pickup.status || '').toLowerCase())
    ) || null;

    const specialRequestPickups = allRequests.map((request) => ({
      _id: request._id,
      pickupNumber: `REQ-${request._id.toString().slice(-6).toUpperCase()}`,
      customerName: request.requester?.name || 'Collection requester',
      customerPhone: request.requester?.phone,
      address: request.location,
      wasteType: request.wasteType,
      weightKg: request.collectedQuantity ?? request.estimatedQuantity ?? 0,
      scheduledTime: request.preferredTime || '',
      status: request.status === 'collected' ? 'completed' : request.status,
      notes: request.driverNotes || request.description,
      createdAt: request.createdAt,
    }));
    const stopSummary = allRoutes.reduce((summary, route) => {
      const stops = route.routeStops?.length ? route.routeStops : route.stops || [];
      const runs = [...(route.runHistory || []).map((run) => run.stops || []), stops];
      for (const runStops of runs) {
        summary.assigned += runStops.length;
        summary.collected += runStops.filter((stop) => stop.status === 'collected').length;
        summary.completed += runStops.filter((stop) => ['collected', 'skipped'].includes(stop.status)).length;
      }
      return summary;
    }, { assigned: 0, completed: 0, collected: 0 });
    stopSummary.remaining = Math.max(0, stopSummary.assigned - stopSummary.completed);
    const weighInTotals = weighIns.reduce((totals, weighIn) => {
      for (const category of ['organic', 'plasticPaper', 'glassOthers']) {
        totals[category] += Number(weighIn.weightsKg?.[category]) || 0;
      }
      return totals;
    }, { organic: 0, plasticPaper: 0, glassOthers: 0 });

    return res.status(200).json({
      success: true,
      driver,
      todayPickups,
      routes: currentDayRoutes,
      stopSummary,
      specialRequestPickups,
      weighInHistory: weighIns,
      weighInTotals,
      metrics: {
        totalPickups: todayPickups.length,
        completedPickups: completedPickupRecords.length,
        remainingPickups,
        cancelledPickups: cancelledPickupRecords.length,
        collectedStops: collectedStops.length,
        totalCollectedWeight,
        collectedByCategory,
        progressPercent: todayStops.length === 0 ? 0 : Math.round((completedStops.length / todayStops.length) * 100),
        totalRouteStops: todayStops.length,
        completedRouteStops: completedStops.length,
        remainingRouteStops: remainingStops.length,
        collectedRouteStops: collectedStops.length,
      },
      nextPickup,
    });
  } catch (error) {
    console.error('Error in getDashboardOverview:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve dashboard overview',
      error: error.message,
    });
  }
};

/**
 * @desc    Get all pickups scheduled for today
 * @route   GET /api/driver/schedule/today
 * @access  Private (Driver only)
 */
exports.getTodaySchedule = async (req, res) => {
  try {
    const driverId = req.user._id;

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const [legacyPickups, requests] = await Promise.all([Pickup.find({
      driverId,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    }).sort({ createdAt: 1 }), CollectionRequest.find(getTodayRequestFilter(driverId, startOfDay, endOfDay))
      .sort({ preferredTime: 1, createdAt: 1 }).populate('requester', 'name phone')]);
    const pickups = [
      ...requests.map((request) => ({
        _id: request._id,
        pickupNumber: `REQ-${request._id.toString().slice(-6).toUpperCase()}`,
        customerName: request.requester?.name || 'Collection requester',
        customerPhone: request.requester?.phone,
        address: request.location,
        wasteType: request.wasteType,
        weightKg: request.collectedQuantity ?? request.estimatedQuantity ?? 0,
        scheduledTime: request.preferredTime || '',
        status: request.status === 'collected' ? 'completed' : request.status,
        notes: request.driverNotes || request.description,
      })),
      ...legacyPickups.map((pickup) => pickup.toObject()),
    ];

    res.status(200).json({
      success: true,
      count: pickups.length,
      pickups,
    });
  } catch (error) {
    console.error('Error in getTodaySchedule:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve today schedule',
      error: error.message,
    });
  }
};

/**
 * @desc    Toggle driver online/offline availability status
 * @route   PATCH /api/driver/availability
 * @access  Private (Driver only)
 */
exports.updateAvailability = async (req, res) => {
  try {
    const driverId = req.user._id;

    const driver = await User.findById(driverId);
    if (!driver) {
      return res.status(404).json({ message: 'Driver not found' });
    }

    // Toggle current availability state
    driver.isAvailable = !driver.isAvailable;
    await driver.save();

    res.status(200).json({
      success: true,
      isAvailable: driver.isAvailable,
      message: `Availability updated to ${driver.isAvailable ? 'Available' : 'Unavailable'}`,
    });
  } catch (error) {
    console.error('Error in updateAvailability:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update availability status',
      error: error.message,
    });
  }
};

/**
 * @desc    Update status of a pickup (e.g., accepted, completed, cancelled)
 * @route   PATCH /api/driver/pickups/:id/status
 * @access  Private (Driver only)
 */
exports.updatePickupStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const driverId = req.user._id;

    const pickup = await Pickup.findOne({ _id: id, driverId });
    if (pickup) {
      const validStatuses = ['scheduled', 'accepted', 'en_route', 'completed', 'cancelled'];
      if (!status || !validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid status provided',
        });
      }

      pickup.status = status;
      if (status === 'completed') {
        pickup.completedAt = new Date();
      }
      await pickup.save();

      return res.status(200).json({
        success: true,
        message: `Pickup status updated to ${status}`,
        pickup,
      });
    }

    const request = await CollectionRequest.findOne({ _id: id, assignedDriver: driverId });
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Pickup task not found or unauthorized',
      });
    }

    const validTransitions = {
      requested: ['accepted', 'cancelled'],
      accepted: ['scheduled', 'cancelled'],
      scheduled: ['collected', 'cancelled'],
      collected: [],
      cancelled: [],
    };
    if (!validTransitions[request.status]?.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot transition from "${request.status}" to "${status}"`,
      });
    }

    request.status = status;
    request.statusHistory.push({
      status,
      note: `Status updated by assigned driver to ${status}`,
    });
    await request.save();

    res.status(200).json({
      success: true,
      message: `Pickup status updated to ${status}`,
      pickup: {
        _id: request._id,
        status: request.status,
        weightKg: request.collectedQuantity ?? request.estimatedQuantity,
        wasteType: request.wasteType,
        notes: request.driverNotes,
      },
    });
  } catch (error) {
    console.error('Error in updatePickupStatus:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update pickup status',
      error: error.message,
    });
  }
};

/** Update collection details recorded by the assigned driver. */
exports.updatePickupDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const driverId = req.user._id;
    const { weightKg, wasteType, notes } = req.body;

    if (weightKg !== undefined &&
        (!Number.isFinite(Number(weightKg)) || Number(weightKg) < 0)) {
      return res.status(400).json({ success: false, message: 'Weight must be zero or more' });
    }

    const pickup = await Pickup.findOne({ _id: id, driverId });
    if (pickup) {
      if (weightKg !== undefined) pickup.weightKg = Number(weightKg);
      if (wasteType !== undefined) pickup.wasteType = String(wasteType).trim();
      if (notes !== undefined) pickup.notes = String(notes).trim();
      await pickup.save();
      return res.status(200).json({ success: true, pickup });
    }

    const request = await CollectionRequest.findOne({ _id: id, assignedDriver: driverId });
    if (!request) {
      return res.status(404).json({ success: false, message: 'Assigned pickup not found' });
    }
    if (weightKg !== undefined) request.collectedQuantity = Number(weightKg);
    if (wasteType !== undefined) request.wasteType = String(wasteType).trim().toLowerCase();
    if (notes !== undefined) request.driverNotes = String(notes).trim();
    await request.save();

    return res.status(200).json({
      success: true,
      pickup: {
        _id: request._id,
        weightKg: request.collectedQuantity ?? request.estimatedQuantity,
        wasteType: request.wasteType,
        notes: request.driverNotes,
      },
    });
  } catch (error) {
    console.error('Update pickup details error:', error);
    return res.status(500).json({ success: false, message: 'Unable to save pickup details' });
  }
};

/** Record category totals weighed at the recycling center after a route/day. */
exports.createWasteWeighIn = async (req, res) => {
  try {
    const { routeId, weightsKg, notes } = req.body;
    const categories = ['organic', 'plasticPaper', 'glassOthers'];
    if (!weightsKg || categories.some((key) => !Number.isFinite(Number(weightsKg[key])) || Number(weightsKg[key]) < 0)) {
      return res.status(400).json({ success: false, message: 'Enter a valid zero or greater weight for each category' });
    }

    let route = null;
    if (routeId) {
      route = await Route.findOne({ _id: routeId, assignedDriver: req.user._id });
      if (!route) return res.status(404).json({ success: false, message: 'Assigned route not found' });
    }

    const weighIn = await WasteWeighIn.create({
      driver: req.user._id,
      route: route?._id || null,
      weightsKg: Object.fromEntries(categories.map((key) => [key, Number(weightsKg[key])])),
      notes: String(notes || '').trim(),
    });
    return res.status(201).json({ success: true, weighIn, message: 'Recycling center weights saved' });
  } catch (error) {
    console.error('Create waste weigh-in error:', error);
    return res.status(500).json({ success: false, message: 'Unable to save recycling center weights' });
  }
};

/**
 * @desc    Save the authenticated driver's latest location
 * @route   POST /api/driver/location
 * @access  Private (Driver only)
 */
exports.updateLiveLocation = async (req, res) => {
  try {
    const { lat, lng } = req.body;
    if (!Number.isFinite(lat) || !Number.isFinite(lng) ||
        lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({
        success: false,
        message: 'Valid latitude and longitude are required',
      });
    }

    const updatedAt = new Date();
    const driver = await User.findByIdAndUpdate(
      req.user._id,
      { $set: { liveLocation: { lat, lng, updatedAt } } },
      { returnDocument: 'after' }
    ).select('liveLocation');

    return res.status(200).json({ success: true, liveLocation: driver.liveLocation });
  } catch (error) {
    console.error('Update live location error:', error);
    return res.status(500).json({ success: false, message: 'Unable to update live location' });
  }
};

/**
 * @desc    Update a stop on a route assigned to the authenticated driver
 * @route   PATCH /api/driver/routes/:routeId/stops/:stopId/status
 * @access  Private (Driver only)
 */
exports.updateAssignedRouteStopStatus = async (req, res) => {
  try {
    const { routeId, stopId } = req.params;
    const { status } = req.body;
    if (!['pending', 'collected', 'skipped'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid stop status' });
    }

    // `assignedDriver` is the repository's route ownership field.
    const route = await Route.findOne({ _id: routeId, assignedDriver: req.user._id });
    if (!route) {
      return res.status(404).json({ success: false, message: 'Assigned route not found' });
    }
    if (route.status === 'completed') {
      return res.status(409).json({ success: false, message: 'This route has ended. Reset it to start another day.' });
    }

    const stops = route.routeStops?.length ? route.routeStops : route.stops;
    let stop = stopId ? stops.id(stopId) : null;

    // Older routes can have separately generated IDs in `stops` and
    // `routeStops`. The client submits the index from the same route payload
    // as a safe fallback when those embedded IDs do not match.
    const requestedIndex = Number.parseInt(req.body.stopIndex, 10);
    if (!stop && Number.isInteger(requestedIndex) &&
        requestedIndex >= 0 && requestedIndex < stops.length) {
      stop = stops[requestedIndex];
    }

    if (!stop) {
      return res.status(404).json({ success: false, message: 'Route stop not found' });
    }

    stop.status = status;
    stop.updatedAt = new Date();
    route.routeStops = stops;
    route.stops = stops;
    await route.save();

    return res.status(200).json({ success: true, routeStops: route.routeStops });
  } catch (error) {
    console.error('Update assigned route stop error:', error);
    return res.status(500).json({ success: false, message: 'Unable to update route stop' });
  }
};

/** End today's assigned route while preserving its stop results for history. */
exports.endAssignedRoute = async (req, res) => {
  try {
    const route = await Route.findOne({ _id: req.params.routeId, assignedDriver: req.user._id });
    if (!route) return res.status(404).json({ success: false, message: 'Assigned route not found' });
    if (route.status === 'completed') return res.status(409).json({ success: false, message: 'This route has already ended' });
    const now = new Date();
    route.status = 'completed';
    route.routeStatus = 'Inactive';
    route.lastRunEndedAt = now;
    await route.save();
    return res.status(200).json({ success: true, route, message: 'Route ended. You can now drop collected waste at the recycling center.' });
  } catch (error) {
    console.error('End assigned route error:', error);
    return res.status(500).json({ success: false, message: 'Unable to end this route' });
  }
};

/** Archive the completed run and reset stop statuses for another day. */
exports.resetAssignedRoute = async (req, res) => {
  try {
    const route = await Route.findOne({ _id: req.params.routeId, assignedDriver: req.user._id });
    if (!route) return res.status(404).json({ success: false, message: 'Assigned route not found' });
    if (route.status !== 'completed') return res.status(409).json({ success: false, message: 'End this route before resetting it for another day' });
    const now = new Date();
    const stops = route.routeStops?.length ? route.routeStops : route.stops || [];
    route.runHistory.push({ startedAt: route.runStartedAt || route.createdAt || now, endedAt: route.lastRunEndedAt || now, stops: stops.map((stop) => stop.toObject()) });
    for (const stop of stops) {
      stop.status = 'pending';
      stop.updatedAt = null;
    }
    route.routeStops = stops;
    route.stops = stops;
    route.status = 'Active';
    route.routeStatus = 'Active';
    route.runStartedAt = now;
    route.lastRunEndedAt = null;
    await route.save();
    return res.status(200).json({ success: true, route, message: 'Route reset and ready for another day.' });
  } catch (error) {
    console.error('Reset assigned route error:', error);
    return res.status(500).json({ success: false, message: 'Unable to reset this route' });
  }
};
