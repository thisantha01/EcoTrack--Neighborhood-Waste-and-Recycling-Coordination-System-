const mongoose = require('mongoose');

const Route = require('../models/Route');
const CollectionRequest = require('../models/CollectionRequest');
const DriverAssignment = require('../models/DriverAssignment');
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
      targetWasteType,
      weeklyCategorySchedule,
      routeStops,
      stops,
    } = req.body;

    if (!routeName || !zone || !date) {
      return res.status(400).json({
        success: false,
        message: 'Route name, zone and date are required',
      });
    }

    const initialStops = (Array.isArray(routeStops) && routeStops.length > 0)
      ? routeStops
      : (Array.isArray(stops) ? stops : []);

    const formattedStops = initialStops.map((stop, index) => ({
      collectionRequestId: stop.collectionRequestId || null,
      location: {
        lat: Number(stop.location?.lat ?? stop.lat ?? 6.9061),
        lng: Number(stop.location?.lng ?? stop.lng ?? 79.9696),
      },
      address: stop.address || `Stop ${index + 1}`,
      sequenceOrder: Number(stop.sequenceOrder) || (index + 1),
      status: stop.status || 'pending',
    }));

    const coords = areaCoordinates && Number.isFinite(Number(areaCoordinates.lat)) && Number.isFinite(Number(areaCoordinates.lng))
      ? { lat: Number(areaCoordinates.lat), lng: Number(areaCoordinates.lng) }
      : (formattedStops.length > 0 ? formattedStops[0].location : { lat: 6.9061, lng: 79.9696 });

    const route = await Route.create({
      routeName: routeName.trim(),
      zone: zone.trim(),
      date,
      assignedDriver: assignedDriver || null,
      description: description || '',
      assignedLocations: assignedLocations && assignedLocations.length ? assignedLocations : [zone.trim()],
      areaCoordinates: coords,
      operatingDays: operatingDays || [],
      targetWasteType: targetWasteType || 'weekly_schedule',
      weeklyCategorySchedule: Array.isArray(weeklyCategorySchedule) ? weeklyCategorySchedule : [],
      routeStops: formattedStops,
      stops: formattedStops,
      status: assignedDriver ? 'Active' : 'Inactive',
      routeStatus: assignedDriver ? 'Active' : 'Inactive',
    });

    const populatedRoute = await populateRoute(Route.findById(route._id));

    return res.status(201).json({
      success: true,
      message: 'Route created successfully',
      route: populatedRoute || route,
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
      sequenceOrder,
    } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
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

    let request = null;
    if (collectionRequestId && mongoose.isValidObjectId(collectionRequestId)) {
      request = await CollectionRequest.findById(collectionRequestId);
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Collection request not found',
        });
      }

      const alreadyAdded = route.routeStops.some(
        (stop) => stop.collectionRequestId && stop.collectionRequestId.toString() === collectionRequestId
      );

      if (alreadyAdded) {
        return res.status(400).json({
          success: false,
          message: 'Collection request is already on this route',
        });
      }
    }

    const nextSequenceOrder = Number(sequenceOrder) || (route.routeStops.reduce(
      (highestOrder, stop) => Math.max(highestOrder, stop.sequenceOrder || 0),
      0
    ) + 1);

    const requestCoordinates = request?.coordinates || {};
    const lat = location?.lat ?? requestCoordinates.lat ?? 6.9061;
    const lng = location?.lng ?? requestCoordinates.lng ?? 79.9696;
    const stopAddress = address || request?.location || `Stop ${nextSequenceOrder}`;

    route.routeStops.push({
      collectionRequestId: request ? request._id : null,
      location: {
        lat: Number(lat),
        lng: Number(lng),
      },
      address: stopAddress,
      sequenceOrder: nextSequenceOrder,
      status: 'pending',
    });

    if (request) {
      if (request.status !== 'scheduled') {
        request.status = 'scheduled';
        request.statusHistory.push({
          status: 'scheduled',
          note: `Added to route ${route.routeName}`,
        });
        await request.save();
      }

      if (route.assignedDriver) {
        await DriverAssignment.findOneAndUpdate(
          { requestId: request._id },
          {
            requestId: request._id,
            driverId: route.assignedDriver,
            assignedBy: req.user?._id || route.assignedDriver,
            assignedAt: new Date(),
            status: 'Assigned',
            notes: `Assigned via route ${route.routeName}`,
          },
          { upsert: true, new: true }
        );
      }
    }

    syncRouteStops(route);
    await route.save();

    const populatedRoute = await populateRoute(Route.findById(route._id));

    return res.status(200).json({
      success: true,
      message: 'Stop added to route successfully',
      route: populatedRoute,
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
    const { collectionRequestId, stopId, sequenceOrder } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    if (!stopId && !collectionRequestId && sequenceOrder === undefined) {
      return res.status(400).json({
        success: false,
        message: 'A stop ID, collection request ID, or sequence order is required to remove a stop',
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
    let stopIndex = -1;

    if (stopId) {
      stopIndex = route.routeStops.findIndex(
        (stop) => stop._id && stop._id.toString() === stopId.toString()
      );
    }
    if (stopIndex === -1 && collectionRequestId) {
      stopIndex = route.routeStops.findIndex(
        (stop) => stop.collectionRequestId && stop.collectionRequestId.toString() === collectionRequestId.toString()
      );
    }
    if (stopIndex === -1 && sequenceOrder !== undefined && sequenceOrder !== null) {
      stopIndex = route.routeStops.findIndex(
        (stop) => stop.sequenceOrder === Number(sequenceOrder)
      );
    }

    if (stopIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Stop not found on this route',
      });
    }

    const removedStop = route.routeStops[stopIndex];
    route.routeStops.splice(stopIndex, 1);
    route.routeStops.forEach((stop, index) => {
      stop.sequenceOrder = index + 1;
    });

    syncRouteStops(route);
    await route.save();

    // If removed stop was linked to a collection request, revert its status
    if (removedStop.collectionRequestId) {
      const colReq = await CollectionRequest.findById(removedStop.collectionRequestId);
      if (colReq && ['scheduled', 'accepted'].includes(colReq.status)) {
        colReq.status = 'requested';
        colReq.assignedDriver = null;
        colReq.statusHistory.push({
          status: 'requested',
          note: `Removed from route ${route.routeName}`,
        });
        await colReq.save();
      }
      await DriverAssignment.findOneAndDelete({ requestId: removedStop.collectionRequestId });
    }

    const populatedRoute = await populateRoute(Route.findById(route._id));

    return res.status(200).json({
      success: true,
      message: 'Stop removed from route',
      route: populatedRoute || route,
    });
  } catch (error) {
    console.error('Remove route stop error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to remove stop from route',
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
      const dateObj = new Date(scheduledDate);
      const scheduledDayLocal = dateObj.toLocaleDateString('en-US', { weekday: 'long' });
      const scheduledDayUTC = dateObj.toLocaleDateString('en-US', { weekday: 'long', timeZone: 'UTC' });
      if (!route.operatingDays.includes(scheduledDayLocal) && !route.operatingDays.includes(scheduledDayUTC)) {
        return res.status(400).json({
          success: false,
          message: `This route operates on ${route.operatingDays.join(', ')}`,
        });
      }
    }

    syncRouteStops(route);
    const alreadyAdded = route.routeStops.some(
      (stop) => stop.collectionRequestId && stop.collectionRequestId.toString() === collectionRequestId
    );

    if (!alreadyAdded) {
      const coordinates = request.coordinates || {};
      const stopLat = (coordinates && typeof coordinates.lat === 'number')
        ? coordinates.lat
        : (route.areaCoordinates?.lat || 6.9061);
      const stopLng = (coordinates && typeof coordinates.lng === 'number')
        ? coordinates.lng
        : (route.areaCoordinates?.lng || 79.9696);

      const nextSequenceOrder = route.routeStops.reduce(
        (highestOrder, stop) => Math.max(highestOrder, stop.sequenceOrder || 0),
        0
      ) + 1;

      route.routeStops.push({
        collectionRequestId: request._id,
        location: {
          lat: stopLat,
          lng: stopLng,
        },
        address: request.location || 'Malabe Area Stop',
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

    if (route.assignedDriver) {
      await DriverAssignment.findOneAndUpdate(
        { requestId: request._id },
        {
          requestId: request._id,
          driverId: route.assignedDriver,
          assignedBy: req.user?._id || route.assignedDriver,
          assignedAt: new Date(),
          status: 'Assigned',
          notes: `Assigned via route ${route.routeName}`,
        },
        { upsert: true, new: true }
      );
    }

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
      message: error.message || 'Unable to confirm collection request route',
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
        { status: { $in: ['Active', 'assigned', 'in-progress', 'draft'] } },
      ],
    })
      .populate('assignedDriver', 'name phone vehicleType');

    if (!routes.length) {
      return res.status(404).json({ success: false, message: 'No active routes found' });
    }

    const earthRadius = 6371;
    const calcDistance = (pointLat, pointLng) => {
      const latDistance = ((pointLat - lat) * Math.PI) / 180;
      const lngDistance = ((pointLng - lng) * Math.PI) / 180;
      const value = Math.sin(latDistance / 2) ** 2 +
        Math.cos((lat * Math.PI) / 180) * Math.cos((pointLat * Math.PI) / 180) * Math.sin(lngDistance / 2) ** 2;
      return earthRadius * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
    };

    const routeDistance = (route) => {
      let minDistance = Number.POSITIVE_INFINITY;
      let closestPointName = null;

      // 1. Check areaCoordinates
      const area = route.areaCoordinates || {};
      if (Number.isFinite(area.lat) && Number.isFinite(area.lng)) {
        const d = calcDistance(area.lat, area.lng);
        if (d < minDistance) {
          minDistance = d;
          closestPointName = `${route.zone || route.routeName} Center`;
        }
      }

      // 2. Check routeStops / stops
      const stops = getRouteStops(route);
      for (const stop of stops) {
        const loc = stop.location || {};
        if (Number.isFinite(loc.lat) && Number.isFinite(loc.lng)) {
          const d = calcDistance(loc.lat, loc.lng);
          if (d < minDistance) {
            minDistance = d;
            closestPointName = stop.address || `Stop #${stop.sequenceOrder}`;
          }
        }
      }

      // If zone or routeName contains 'malabe', and target is near Malabe, give slight priority if close
      const isMalabeZone = (route.zone || '').toLowerCase().includes('malabe') ||
                           (route.routeName || '').toLowerCase().includes('malabe');

      return {
        minDistance,
        closestPointName,
        isMalabeZone,
      };
    };

    const ranked = routes.map((route) => {
      const { minDistance, closestPointName, isMalabeZone } = routeDistance(route);
      return {
        route,
        distanceKm: minDistance,
        closestPointName,
        isMalabeZone,
      };
    }).filter((item) => Number.isFinite(item.distanceKm));

    if (!ranked.length) {
      // Fallback: If no routes had coordinates, return the first route with default Malabe distance
      const firstRoute = routes[0];
      return res.status(200).json({
        success: true,
        route: firstRoute,
        distanceKm: 2.5,
        closestPoint: 'Malabe Center',
      });
    }

    ranked.sort((a, b) => a.distanceKm - b.distanceKm);

    const nearest = ranked[0];

    return res.status(200).json({
      success: true,
      route: nearest.route,
      distanceKm: Math.round(nearest.distanceKm * 10) / 10,
      closestPoint: nearest.closestPointName || 'Route area',
    });
  } catch (error) {
    console.error('Suggest route error:', error);
    return res.status(500).json({ success: false, message: 'Unable to suggest route' });
  }
};


// =====================================================
// UPDATE ROUTE
// =====================================================

const updateRoute = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      routeName,
      zone,
      date,
      assignedDriver,
      description,
      assignedLocations,
      areaCoordinates,
      operatingDays,
      targetWasteType,
      weeklyCategorySchedule,
      routeStops,
      stops,
      status,
      routeStatus,
    } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found',
      });
    }

    if (routeName !== undefined) route.routeName = routeName.trim();
    if (zone !== undefined) route.zone = zone.trim();
    if (date !== undefined) route.date = date;
    if (description !== undefined) route.description = description;
    if (operatingDays !== undefined) route.operatingDays = operatingDays;
    if (targetWasteType !== undefined) route.targetWasteType = targetWasteType;
    if (weeklyCategorySchedule !== undefined && Array.isArray(weeklyCategorySchedule)) {
      route.weeklyCategorySchedule = weeklyCategorySchedule;
    }
    if (assignedLocations !== undefined) route.assignedLocations = assignedLocations;

    const newStatus = routeStatus || status;
    if (newStatus !== undefined) {
      route.status = newStatus;
      route.routeStatus = newStatus;
    }

    if (areaCoordinates && Number.isFinite(Number(areaCoordinates.lat)) && Number.isFinite(Number(areaCoordinates.lng))) {
      route.areaCoordinates = {
        lat: Number(areaCoordinates.lat),
        lng: Number(areaCoordinates.lng),
      };
    }

    // Driver update
    const previousDriver = route.assignedDriver ? route.assignedDriver.toString() : null;
    let driverUpdated = false;

    if (assignedDriver !== undefined) {
      const nextDriver = assignedDriver ? assignedDriver.toString() : null;
      if (previousDriver !== nextDriver) {
        driverUpdated = true;
        if (assignedDriver) {
          const driver = await User.findOne({
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
          if (['Inactive', 'draft'].includes(route.status)) {
            route.status = 'Active';
            route.routeStatus = 'Active';
          }
        } else {
          route.assignedDriver = null;
        }
      }
    }

    // Process updated stops if provided
    const newStops = (Array.isArray(routeStops) && routeStops.length > 0)
      ? routeStops
      : (Array.isArray(stops) ? stops : null);

    if (newStops) {
      const formattedStops = newStops.map((stop, index) => ({
        _id: stop._id && mongoose.isValidObjectId(stop._id) ? stop._id : new mongoose.Types.ObjectId(),
        collectionRequestId: stop.collectionRequestId || null,
        location: {
          lat: Number(stop.location?.lat ?? stop.lat ?? 6.9061),
          lng: Number(stop.location?.lng ?? stop.lng ?? 79.9696),
        },
        address: stop.address || `Stop ${index + 1}`,
        sequenceOrder: Number(stop.sequenceOrder) || (index + 1),
        status: stop.status || 'pending',
      }));

      formattedStops.sort((a, b) => (a.sequenceOrder || 0) - (b.sequenceOrder || 0));
      formattedStops.forEach((s, i) => { s.sequenceOrder = i + 1; });

      route.routeStops = formattedStops;
      route.stops = formattedStops;
    }

    syncRouteStops(route);
    await route.save();

    // If driver changed, update DriverAssignments and CollectionRequests
    if (driverUpdated) {
      const requestStops = route.routeStops.filter((s) => s.collectionRequestId);
      for (const stop of requestStops) {
        if (route.assignedDriver) {
          await CollectionRequest.findByIdAndUpdate(stop.collectionRequestId, {
            assignedDriver: route.assignedDriver,
          });
          await DriverAssignment.findOneAndUpdate(
            { requestId: stop.collectionRequestId },
            {
              requestId: stop.collectionRequestId,
              driverId: route.assignedDriver,
              assignedBy: req.user?._id || route.assignedDriver,
              assignedAt: new Date(),
              status: 'Assigned',
              notes: `Route driver updated to ${route.assignedDriver}`,
            },
            { upsert: true, new: true }
          );
        } else {
          await CollectionRequest.findByIdAndUpdate(stop.collectionRequestId, {
            assignedDriver: null,
          });
          await DriverAssignment.findOneAndDelete({ requestId: stop.collectionRequestId });
        }
      }
    }

    const populatedRoute = await populateRoute(Route.findById(route._id));

    return res.status(200).json({
      success: true,
      message: 'Route updated successfully',
      route: populatedRoute || route,
    });
  } catch (error) {
    console.error('Update route error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to update route',
    });
  }
};


// =====================================================
// DELETE ROUTE
// =====================================================

const deleteRoute = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found',
      });
    }

    // Revert associated collection requests
    const stops = getRouteStops(route);
    const reqIds = stops
      .filter((s) => s.collectionRequestId)
      .map((s) => s.collectionRequestId);

    if (reqIds.length > 0) {
      await CollectionRequest.updateMany(
        { _id: { $in: reqIds }, status: { $in: ['scheduled', 'accepted'] } },
        {
          $set: { status: 'requested', assignedDriver: null },
          $push: {
            statusHistory: {
              status: 'requested',
              timestamp: new Date(),
              note: `Route "${route.routeName}" was deleted by manager`,
            },
          },
        }
      );
      await DriverAssignment.deleteMany({ requestId: { $in: reqIds } });
    }

    await Route.findByIdAndDelete(id);

    return res.status(200).json({
      success: true,
      message: `Route "${route.routeName}" deleted successfully`,
    });
  } catch (error) {
    console.error('Delete route error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to delete route',
    });
  }
};


// =====================================================
// REORDER STOPS (EDIT STOP SEQUENCE)
// =====================================================

const reorderStops = async (req, res) => {
  try {
    const { id } = req.params;
    const { stops, routeStops } = req.body;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid route ID',
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Route not found',
      });
    }

    const inputStops = Array.isArray(routeStops) ? routeStops : (Array.isArray(stops) ? stops : null);
    if (!inputStops) {
      return res.status(400).json({
        success: false,
        message: 'Stops array is required for reordering',
      });
    }

    syncRouteStops(route);
    const currentStops = route.routeStops;

    const reordered = [];
    inputStops.forEach((inputStop, newIndex) => {
      const inputId = (typeof inputStop === 'object' && inputStop._id)
        ? inputStop._id.toString()
        : (typeof inputStop === 'string' ? inputStop : null);

      const existing = currentStops.find((s) => {
        if (inputId && s._id && s._id.toString() === inputId) return true;
        if (typeof inputStop === 'object') {
          if (inputStop.collectionRequestId && s.collectionRequestId && s.collectionRequestId.toString() === inputStop.collectionRequestId.toString()) return true;
          if (inputStop.address && s.address === inputStop.address) return true;
        }
        return false;
      });

      if (existing) {
        existing.sequenceOrder = newIndex + 1;
        reordered.push(existing);
      } else if (typeof inputStop === 'object') {
        reordered.push({
          collectionRequestId: inputStop.collectionRequestId || null,
          location: {
            lat: Number(inputStop.location?.lat ?? inputStop.lat ?? 6.9061),
            lng: Number(inputStop.location?.lng ?? inputStop.lng ?? 79.9696),
          },
          address: inputStop.address || `Stop ${newIndex + 1}`,
          sequenceOrder: newIndex + 1,
          status: inputStop.status || 'pending',
        });
      }
    });

    if (reordered.length > 0) {
      route.routeStops = reordered;
      route.stops = reordered;
    }

    syncRouteStops(route);
    await route.save();

    const populatedRoute = await populateRoute(Route.findById(route._id));

    return res.status(200).json({
      success: true,
      message: 'Stop sequence updated successfully',
      route: populatedRoute || route,
    });
  } catch (error) {
    console.error('Reorder stops error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Unable to update stop sequence',
    });
  }
};

/**
 * @desc Get public route schedule for residents and drivers with today's category
 * @route GET /api/manager/routes/schedule
 */
const getPublicRouteSchedule = async (req, res) => {
  try {
    const { zone } = req.query;
    const filter = {
      $or: [
        { routeStatus: 'Active' },
        { status: { $in: ['Active', 'assigned', 'in-progress'] } },
      ],
    };
    if (zone && zone.trim()) {
      filter.zone = new RegExp(zone.trim(), 'i');
    }

    const routes = await Route.find(filter)
      .populate('assignedDriver', 'name phone vehicleType')
      .lean();

    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const currentDay = days[new Date().getDay()];

    const scheduledRoutes = routes.map((r) => {
      let todayCategory = 'organic';
      if (r.targetWasteType && r.targetWasteType !== 'weekly_schedule') {
        todayCategory = r.targetWasteType;
      } else if (Array.isArray(r.weeklyCategorySchedule) && r.weeklyCategorySchedule.length > 0) {
        const found = r.weeklyCategorySchedule.find((s) => s.day === currentDay);
        if (found && found.category) {
          todayCategory = found.category;
          // Legacy migration: Tuesday/Thursday was previously plastic_paper, Wednesday was organic, Friday was organic
          if ((currentDay === 'Tuesday' || currentDay === 'Thursday') && (todayCategory === 'plastic_paper' || todayCategory === 'plastic' || todayCategory === 'paper')) {
            todayCategory = 'special_requests';
          } else if (currentDay === 'Wednesday' && todayCategory === 'organic') {
            todayCategory = 'plastic_paper';
          } else if (currentDay === 'Friday' && todayCategory === 'organic') {
            todayCategory = 'glass_others';
          }
        } else {
          // Default fallbacks based on updated municipal schedule
          if (currentDay === 'Tuesday' || currentDay === 'Thursday') {
            todayCategory = 'special_requests';
          } else if (currentDay === 'Wednesday') {
            todayCategory = 'plastic_paper';
          } else if (currentDay === 'Friday') {
            todayCategory = 'glass_others';
          } else if (currentDay === 'Saturday') {
            todayCategory = 'special_requests';
          } else {
            todayCategory = 'organic';
          }
        }
      } else {
        if (currentDay === 'Tuesday' || currentDay === 'Thursday') {
          todayCategory = 'special_requests';
        } else if (currentDay === 'Wednesday') {
          todayCategory = 'plastic_paper';
        } else if (currentDay === 'Friday') {
          todayCategory = 'glass_others';
        } else if (currentDay === 'Saturday') {
          todayCategory = 'special_requests';
        } else {
          todayCategory = 'organic';
        }
      }

      // Normalize older category names into the canonical categories
      if (todayCategory === 'plastic' || todayCategory === 'paper') {
        todayCategory = 'plastic_paper';
      } else if (todayCategory === 'glass_metal' || todayCategory === 'glass' || todayCategory === 'other') {
        todayCategory = 'glass_others';
      }

      const operatesToday = Array.isArray(r.operatingDays) && r.operatingDays.includes(currentDay);

      return {
        ...r,
        currentDay,
        todayCategory,
        operatesToday,
      };
    });

    return res.status(200).json({
      success: true,
      currentDay,
      routes: scheduledRoutes,
    });
  } catch (error) {
    console.error('Get public route schedule error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch route schedule',
    });
  }
};

// =====================================================
// UPDATE ROUTE STOP STATUS
// =====================================================

const updateStopStatus = async (req, res) => {
  try {
    const { id, stopIndex } = req.params;
    const { status, reason } = req.body;

    if (!['pending', 'collected', 'skipped'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Status must be 'pending', 'collected', or 'skipped'",
      });
    }

    const route = await Route.findById(id);
    if (!route) {
      return res.status(404).json({ success: false, message: 'Route not found' });
    }

    syncRouteStops(route);
    const idx = parseInt(stopIndex, 10);
    if (isNaN(idx) || idx < 0 || idx >= route.routeStops.length) {
      return res.status(400).json({ success: false, message: 'Invalid stop index' });
    }

    route.routeStops[idx].status = status;

    // If attached to a customer collection request, synchronize collection status
    const reqId = route.routeStops[idx].collectionRequestId;
    if (reqId) {
      const collectionReq = await CollectionRequest.findById(reqId);
      if (collectionReq) {
        if (status === 'collected') {
          collectionReq.status = 'collected';
          collectionReq.statusHistory.push({
            status: 'collected',
            note: reason || `Collected on route ${route.routeName}`,
          });
        } else if (status === 'skipped') {
          collectionReq.statusHistory.push({
            status: collectionReq.status || 'scheduled',
            note: reason ? `Stop skipped: ${reason}` : 'Stop skipped during collection',
          });
        } else if (status === 'pending') {
          collectionReq.status = 'scheduled';
        }
        await collectionReq.save();
      }
    }

    syncRouteStops(route);
    await route.save();

    const populated = await populateRoute(Route.findById(route._id));

    return res.status(200).json({
      success: true,
      message: `Stop marked as ${status}`,
      route: populated,
    });
  } catch (error) {
    console.error('Update stop status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update stop status',
      error: error.message,
    });
  }
};

// =====================================================
// AUTO-OPTIMIZE ROUTE SEQUENCE (PROXIMITY TSP)
// =====================================================

const calculateDistanceKm = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

const optimizeRouteSequence = async (req, res) => {
  try {
    const { id } = req.params;
    const route = await Route.findById(id);

    if (!route) {
      return res.status(404).json({ success: false, message: 'Route not found' });
    }

    syncRouteStops(route);
    const stops = [...route.routeStops];

    if (stops.length > 2) {
      // Retain first stop as starting depot/waypoint
      const ordered = [stops[0]];
      const remaining = stops.slice(1);

      let currentLat = stops[0].location?.lat ?? 6.9061;
      let currentLng = stops[0].location?.lng ?? 79.9696;

      while (remaining.length > 0) {
        let bestIdx = 0;
        let minDistance = Infinity;

        for (let i = 0; i < remaining.length; i++) {
          const lat = remaining[i].location?.lat ?? 6.9061;
          const lng = remaining[i].location?.lng ?? 79.9696;
          const d = calculateDistanceKm(currentLat, currentLng, lat, lng);
          if (d < minDistance) {
            minDistance = d;
            bestIdx = i;
          }
        }

        const nextStop = remaining.splice(bestIdx, 1)[0];
        ordered.push(nextStop);
        currentLat = nextStop.location?.lat ?? currentLat;
        currentLng = nextStop.location?.lng ?? currentLng;
      }

      // Re-assign sequence order 1, 2, 3...
      for (let i = 0; i < ordered.length; i++) {
        ordered[i].sequenceOrder = i + 1;
      }

      route.routeStops = ordered;
      route.stops = ordered;
      await route.save();
    }

    const populated = await populateRoute(Route.findById(route._id));

    return res.status(200).json({
      success: true,
      message: 'Route sequence successfully auto-optimized by proximity',
      route: populated,
    });
  } catch (error) {
    console.error('Optimize route sequence error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to optimize route sequence',
      error: error.message,
    });
  }
};

module.exports = {
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
};

