const mongoose = require('mongoose');

const Route = require('../models/Route');
const CollectionRequest = require('../models/CollectionRequest');
const User = require('../models/User');

const getRouteStops = (route) => (
  route.routeStops?.length ? route.routeStops : (route.stops || [])
);

const syncRouteStops = (route) => {
  route.routeStops = getRouteStops(route);
  route.stops = route.routeStops;
};

const populateRoute = (query) => query
  .populate('assignedDriver', 'name phone vehicleType')
  .populate({
    path: 'routeStops.collectionRequestId',
    populate: [
      { path: 'requester', select: 'name email phone location' },
      { path: 'assignedDriver', select: 'name phone vehicleType' },
    ],
  });


// =====================================================
// CREATE ROUTE
// =====================================================

const createRoute = async (req, res) => {
  try {
    const {
      routeName,
      zone,
      date,
      assignedDriver,
      description,
      assignedLocations,
      areaCoordinates,
      operatingDays,
    } = req.body;

    if (!routeName || !zone || !date) {
      return res.status(400).json({
        success: false,
        message: 'Route name, zone and date are required',
      });
    }

    const route = await Route.create({
      routeName: routeName.trim(),
      zone: zone.trim(),
      date,
      assignedDriver: assignedDriver || null,
      description: description || '',
      assignedLocations: assignedLocations || [],
      areaCoordinates: areaCoordinates || {},
      operatingDays: operatingDays || [],
      status: assignedDriver ? 'Active' : 'Inactive',
      routeStatus: assignedDriver ? 'Active' : 'Inactive',
    });

    return res.status(201).json({
      success: true,
      message: 'Route created successfully',
      route,
    });
  } catch (error) {
    console.error('Create route error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to create route',
    });
  }
};


// =====================================================
// GET ROUTES
// =====================================================

const getRoutes = async (req, res) => {
  try {
    const {
      zone,
      date,
      status,
      page = 1,
      limit = 20,
    } = req.query;

    const filter = {};

    if (zone) {
      filter.zone = zone;
    }

    if (status) {
      filter.status = status;
    }

    if (date) {
      const startOfDay = new Date(date);
      const endOfDay = new Date(date);

      if (Number.isNaN(startOfDay.getTime())) {
        return res.status(400).json({
          success: false,
          message: 'Invalid date filter',
        });
      }

      startOfDay.setHours(0, 0, 0, 0);
      endOfDay.setHours(23, 59, 59, 999);
      filter.date = {
        $gte: startOfDay,
        $lte: endOfDay,
      };
    }

    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const limitNum = Math.min(
      Math.max(parseInt(limit, 10) || 20, 1),
      100
    );
    const skip = (pageNum - 1) * limitNum;

    const [routes, total] = await Promise.all([
      Route.find(filter)
        .sort({ date: 1, createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .populate('assignedDriver', 'name phone vehicleType')
        .populate('routeStops.collectionRequestId', 'wasteType estimatedQuantity location preferredDate preferredTime status'),
      Route.countDocuments(filter),
    ]);

    const routeData = routes.map((route) => ({
      ...route.toObject(),
      activeStopCount: getRouteStops(route).filter((stop) => stop.status === 'pending').length,
    }));

    return res.status(200).json({
      success: true,
      routes: routeData,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    console.error('Get routes error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch routes',
    });
  }
};


// =====================================================
// GET SINGLE ROUTE
// =====================================================

const getRoute = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    const route = await populateRoute(Route.findById(id));

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found',
      });
    }

    return res.status(200).json({
      success: true,
      route,
    });
  } catch (error) {
    console.error('Get route error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch route',
    });
  }
};


// =====================================================
// ADD STOP TO ROUTE
// =====================================================

const addStop = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      collectionRequestId,
      location,
      address,
    } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    if (!mongoose.isValidObjectId(collectionRequestId)) {
      return res.status(400).json({
        success: false,
        message: 'Valid collection request ID is required',
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found',
      });
    }

    const request = await CollectionRequest.findById(collectionRequestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Collection request not found',
      });
    }

    syncRouteStops(route);
    const alreadyAdded = route.routeStops.some(
      (stop) => stop.collectionRequestId.toString() === collectionRequestId
    );

    if (alreadyAdded) {
      return res.status(400).json({
        success: false,
        message: 'Collection request is already on this route',
      });
    }

    const nextSequenceOrder = route.routeStops.reduce(
      (highestOrder, stop) => Math.max(highestOrder, stop.sequenceOrder || 0),
      0
    ) + 1;

    const requestCoordinates = request.coordinates || {};
    route.routeStops.push({
      collectionRequestId: request._id,
      location: location || {
        lat: requestCoordinates.lat,
        lng: requestCoordinates.lng,
      },
      address: address || request.location,
      sequenceOrder: nextSequenceOrder,
      status: 'pending',
    });

    if (request.status !== 'scheduled') {
      request.status = 'scheduled';
      request.statusHistory.push({
        status: 'scheduled',
        note: `Added to route ${route.routeName}`,
      });
      await request.save();
    }

    syncRouteStops(route);
    await route.save();

    return res.status(200).json({
      success: true,
      message: 'Collection request added to route',
      route,
      request,
    });
  } catch (error) {
    console.error('Add route stop error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to add stop to route',
    });
  }
};


// =====================================================
// REMOVE STOP FROM ROUTE
// =====================================================

const removeStop = async (req, res) => {
  try {
    const { id } = req.params;
    const { collectionRequestId } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    if (!mongoose.isValidObjectId(collectionRequestId)) {
      return res.status(400).json({
        success: false,
        message: 'Valid collection request ID is required',
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found',
      });
    }

    syncRouteStops(route);
    const stopIndex = route.routeStops.findIndex(
      (stop) => stop.collectionRequestId.toString() === collectionRequestId
    );

    if (stopIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Stop not found on this route',
      });
    }

    route.routeStops.splice(stopIndex, 1);
    route.routeStops.forEach((stop, index) => {
      stop.sequenceOrder = index + 1;
    });

    syncRouteStops(route);
    await route.save();

    return res.status(200).json({
      success: true,
      message: 'Stop removed from route',
      route,
    });
  } catch (error) {
    console.error('Remove route stop error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to remove stop from route',
    });
  }
};


// =====================================================
// CONFIRM REQUEST ROUTE
// =====================================================

const confirmRequestRoute = async (req, res) => {
  try {
    const { id } = req.params;
    const { collectionRequestId, assignedDriver, scheduledDate, scheduledTime } = req.body;

    if (!mongoose.isValidObjectId(id) || !mongoose.isValidObjectId(collectionRequestId)) {
      return res.status(400).json({
        success: false,
        message: 'Valid route ID and collection request ID are required',
      });
    }

    const route = await Route.findById(id);
    const request = await CollectionRequest.findById(collectionRequestId);

    if (!route) {
      return res.status(404).json({ success: false, message: 'Route not found' });
    }

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Collection request not found',
      });
    }

    if (!route.assignedDriver && !assignedDriver) {
      return res.status(400).json({
        success: false,
        message: 'Assign a driver to the route before confirming a request',
      });
    }

    if (assignedDriver) {
      const driver = await mongoose.model('User').findOne({
        _id: assignedDriver,
        role: 'driver',
        isVerified: true,
      });
      if (!driver) {
        return res.status(400).json({
          success: false,
          message: 'Selected driver is invalid or not verified',
        });
      }
      route.assignedDriver = assignedDriver;
    }

    if (scheduledDate && route.operatingDays.length) {
      const scheduledDay = new Date(scheduledDate).toLocaleDateString('en-US', { weekday: 'long' });
      if (!route.operatingDays.includes(scheduledDay)) {
        return res.status(400).json({
          success: false,
          message: `This route operates on ${route.operatingDays.join(', ')}`,
        });
      }
    }

    syncRouteStops(route);
    const alreadyAdded = route.routeStops.some(
      (stop) => stop.collectionRequestId.toString() === collectionRequestId
    );

    if (!alreadyAdded) {
      const coordinates = request.coordinates || {};
      const nextSequenceOrder = route.routeStops.reduce(
        (highestOrder, stop) => Math.max(highestOrder, stop.sequenceOrder || 0),
        0
      ) + 1;

      route.routeStops.push({
        collectionRequestId: request._id,
        location: {
          lat: coordinates.lat,
          lng: coordinates.lng,
        },
        address: request.location,
        sequenceOrder: nextSequenceOrder,
        status: 'pending',
      });
    }

    request.assignedDriver = route.assignedDriver;
    if (scheduledDate) request.preferredDate = scheduledDate;
    if (scheduledTime) request.preferredTime = scheduledTime;
    if (request.status === 'requested') {
      request.status = 'accepted';
      request.statusHistory.push({
        status: 'accepted',
        note: `Accepted by manager for route ${route.routeName}`,
      });
    }
    if (request.status !== 'scheduled') {
      request.status = 'scheduled';
      request.statusHistory.push({
        status: 'scheduled',
        note: `Route ${route.routeName} confirmed by manager`,
      });
    }

    route.status = ['draft', 'Inactive'].includes(route.status) ? 'Active' : route.status;
    route.routeStatus = 'Active';
    syncRouteStops(route);

    await Promise.all([route.save(), request.save()]);

    const populatedRoute = await populateRoute(Route.findById(route._id));
    await request.populate('assignedDriver', 'name phone vehicleType');

    return res.status(200).json({
      success: true,
      message: 'Collection request confirmed on route',
      route: populatedRoute,
      request,
    });
  } catch (error) {
    console.error('Confirm request route error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to confirm collection request route',
    });
  }
};


// =====================================================
// CHANGE ROUTE DRIVER
// =====================================================

const changeDriver = async (req, res) => {
  try {
    const { id } = req.params;
    const { driverId } = req.body;

    if (!mongoose.isValidObjectId(id) || !mongoose.isValidObjectId(driverId)) {
      return res.status(400).json({ success: false, message: 'Valid route ID and driver ID are required' });
    }

    const driver = await User.findOne({ _id: driverId, role: 'driver', isVerified: true })
      .select('name phone vehicleType');
    if (!driver) {
      return res.status(404).json({ success: false, message: 'Verified driver not found' });
    }

    const route = await Route.findByIdAndUpdate(
      id,
      { assignedDriver: driver._id, status: 'Active', routeStatus: 'Active' },
      { new: true, runValidators: true }
    ).populate('assignedDriver', 'name phone vehicleType');

    if (!route) return res.status(404).json({ success: false, message: 'Route not found' });

    return res.status(200).json({ success: true, message: 'Route driver changed successfully', route });
  } catch (error) {
    console.error('Change route driver error:', error);
    return res.status(500).json({ success: false, message: 'Unable to change route driver' });
  }
};


// =====================================================
// SUGGEST NEAREST ROUTE
// =====================================================

const suggestRoute = async (req, res) => {
  try {
    const lat = Number(req.query.lat);
    const lng = Number(req.query.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return res.status(400).json({ success: false, message: 'Valid lat and lng query parameters are required' });
    }

    const routes = await Route.find({
      $or: [
        { routeStatus: 'Active' },
        { status: { $in: ['Active', 'assigned', 'in-progress'] } },
      ],
    })
      .populate('assignedDriver', 'name phone vehicleType');
    const earthRadius = 6371;
    const distance = (route) => {
      const point = route.areaCoordinates || {};
      if (!Number.isFinite(point.lat) || !Number.isFinite(point.lng)) return Number.POSITIVE_INFINITY;
      const latDistance = ((point.lat - lat) * Math.PI) / 180;
      const lngDistance = ((point.lng - lng) * Math.PI) / 180;
      const value = Math.sin(latDistance / 2) ** 2 +
        Math.cos((lat * Math.PI) / 180) * Math.cos((point.lat * Math.PI) / 180) * Math.sin(lngDistance / 2) ** 2;
      return earthRadius * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
    };

    const ranked = routes.map((route) => ({ route, distanceKm: distance(route) }))
      .sort((left, right) => left.distanceKm - right.distanceKm);
    const nearest = ranked[0];
    if (!nearest || !Number.isFinite(nearest.distanceKm)) {
      return res.status(404).json({ success: false, message: 'No route with configured coordinates found' });
    }

    return res.status(200).json({ success: true, route: nearest.route, distanceKm: nearest.distanceKm });
  } catch (error) {
    console.error('Suggest route error:', error);
    return res.status(500).json({ success: false, message: 'Unable to suggest route' });
  }
};


module.exports = {
  createRoute,
  getRoutes,
  getRoute,
  addStop,
  removeStop,
  confirmRequestRoute,
  changeDriver,
  suggestRoute,
};
