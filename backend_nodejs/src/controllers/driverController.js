const Pickup = require('../models/pickup');
const User = require('../models/User'); 
const Route = require('../models/Route');
const CollectionRequest = require('../models/CollectionRequest');

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
        { status: { $in: ['Active', 'assigned', 'in-progress'] } },
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

    const [requests, legacyPickups, routes] = await Promise.all([
      CollectionRequest.find({
        assignedDriver: driverId,
        preferredDate: { $gte: startOfDay, $lte: endOfDay },
      }).sort({ preferredTime: 1, createdAt: 1 }).populate('requester', 'name phone'),
      Pickup.find({
        driverId,
        createdAt: { $gte: startOfDay, $lte: endOfDay },
      }).sort({ scheduledTime: 1, createdAt: 1 }),
      Route.find({
        assignedDriver: driverId,
        $or: [{ routeStatus: 'Active' }, { status: { $in: ['Active', 'assigned', 'in-progress'] } }],
      }).sort({ date: 1 }),
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

    const completed = todayPickups.filter((pickup) =>
      ['completed', 'collected'].includes((pickup.status || '').toLowerCase())
    );
    const cancelledPickups = todayPickups.filter((pickup) =>
      (pickup.status || '').toLowerCase() === 'cancelled'
    );
    const remainingPickups = todayPickups.length - completed.length - cancelledPickups.length;
    const collectedByCategory = completed.reduce((totals, pickup) => {
      const category = (pickup.wasteType || 'other').toLowerCase();
      totals[category] = (totals[category] || 0) + (Number(pickup.weightKg) || 0);
      return totals;
    }, {});
    const totalCollectedWeight = completed.reduce(
      (total, pickup) => total + (Number(pickup.weightKg) || 0),
      0
    );
    const nextPickup = todayPickups.find((pickup) =>
      !['completed', 'collected', 'cancelled'].includes((pickup.status || '').toLowerCase())
    ) || null;

    return res.status(200).json({
      success: true,
      driver,
      todayPickups,
      routes,
      metrics: {
        totalPickups: todayPickups.length,
        completedPickups: completed.length,
        remainingPickups,
        cancelledPickups: cancelledPickups.length,
        totalCollectedWeight,
        collectedByCategory,
        progressPercent: todayPickups.length === 0 ? 0 : Math.round((completed.length / todayPickups.length) * 100),
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

    const pickups = await Pickup.find({
      driverId,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    }).sort({ createdAt: 1 });

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
