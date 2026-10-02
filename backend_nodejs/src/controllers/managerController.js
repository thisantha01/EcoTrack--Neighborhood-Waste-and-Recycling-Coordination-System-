const CollectionRequest = require('../models/CollectionRequest');
const DriverAssignment = require('../models/DriverAssignment');
const User = require('../models/User');

const getDriverLiveLocation = async (req, res) => {
  try {
    const driver = await User.findOne({ _id: req.params.driverId, role: 'driver' })
      .select('liveLocation');
    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }
    return res.status(200).json({ success: true, liveLocation: driver.liveLocation });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Unable to fetch driver location' });
  }
};


// =====================================================
// GET DASHBOARD STATS
// =====================================================

const getDashboardStats = async (req, res) => {
  try {
    const now = new Date();
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);

    const startOfWeek = new Date(startOfToday);
    const dayOfWeek = startOfWeek.getDay();
    const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    startOfWeek.setDate(startOfWeek.getDate() - daysSinceMonday);

    const startOfMonth = new Date(
      startOfToday.getFullYear(),
      startOfToday.getMonth(),
      1
    );

    const [requestStats, driverStats, busyDriverStats] = await Promise.all([
      CollectionRequest.aggregate([
        {
          $facet: {
            totals: [
              {
                $group: {
                  _id: null,
                  totalCollectionRequests: { $sum: 1 },
                  pendingRequests: {
                    $sum: { $cond: [{ $eq: ['$status', 'requested'] }, 1, 0] },
                  },
                  acceptedRequests: {
                    $sum: { $cond: [{ $eq: ['$status', 'accepted'] }, 1, 0] },
                  },
                  completedRequests: {
                    $sum: { $cond: [{ $eq: ['$status', 'collected'] }, 1, 0] },
                  },
                },
              },
            ],
            today: [
              { $match: { createdAt: { $gte: startOfToday } } },
              { $count: 'count' },
            ],
            weekly: [
              { $match: { createdAt: { $gte: startOfWeek } } },
              { $count: 'count' },
            ],
            monthly: [
              { $match: { createdAt: { $gte: startOfMonth } } },
              { $count: 'count' },
            ],
          },
        },
      ]),
      User.aggregate([
        { $match: { role: 'driver', isVerified: true } },
        { $count: 'count' },
      ]),
      DriverAssignment.aggregate([
        {
          $match: {
            status: { $in: ['Assigned', 'Accepted'] },
          },
        },
        { $group: { _id: '$driverId' } },
        { $count: 'count' },
      ]),
    ]);

    const requestFacet = requestStats[0] || {};
    const totals = requestFacet.totals?.[0] || {};

    return res.status(200).json({
      success: true,
      totalCollectionRequests: totals.totalCollectionRequests || 0,
      pendingRequests: totals.pendingRequests || 0,
      acceptedRequests: totals.acceptedRequests || 0,
      completedRequests: totals.completedRequests || 0,
      totalDriversCount: driverStats[0]?.count || 0,
      busyDriversCount: busyDriverStats[0]?.count || 0,
      todayRequestsCount: requestFacet.today?.[0]?.count || 0,
      weeklyRequestsCount: requestFacet.weekly?.[0]?.count || 0,
      monthlyRequestsCount: requestFacet.monthly?.[0]?.count || 0,
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch dashboard statistics',
    });
  }
};


// =====================================================
// GET COLLECTION REQUESTS (with filtering)
// =====================================================

const getCollectionRequests = async (req, res) => {
  try {
    const {
      status,
      wasteType,
      date,
      page = 1,
      limit = 20,
    } = req.query;

    const filter = {};

    if (status) {
      filter.status = status;
    }

    if (wasteType) {
      filter.wasteType = wasteType;
    }

    if (date) {
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);

      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);

      filter.preferredDate = {
        $gte: startOfDay,
        $lte: endOfDay,
      };
    }

    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 20;
    const skip = (pageNum - 1) * limitNum;

    const requestsQuery = CollectionRequest.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .populate('requester', 'name email phone location')
      .populate('assignedDriver', 'name phone vehicleType')
      .lean();

    // Fetch the page and its total together instead of waiting for two DB round trips.
    const [requests, total] = await Promise.all([
      requestsQuery.exec(),
      CollectionRequest.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      requests,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    console.error('Get collection requests error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch collection requests',
    });
  }
};


// =====================================================
// GET SINGLE REQUEST DETAILS
// =====================================================

const getRequestDetails = async (req, res) => {
  try {
    const { requestId } = req.params;

    const request = await CollectionRequest.findById(requestId)
      .populate('requester', 'name email phone location coordinates')
      .populate('assignedDriver', 'name phone vehicleType licenseNumber location');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Collection request not found',
      });
    }

    // Get assignment details if driver is assigned
    let assignment = null;
    if (request.assignedDriver) {
      assignment = await DriverAssignment.findOne({ requestId: request._id })
        .populate('assignedBy', 'name email')
        .populate('driverId', 'name phone vehicleType');
    }

    return res.status(200).json({
      success: true,
      request: {
        ...request.toObject(),
        assignment,
      },
    });
  } catch (error) {
    console.error('Get request details error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch request details',
    });
  }
};


// =====================================================
// GET AVAILABLE DRIVERS
// =====================================================

const getAvailableDrivers = async (req, res) => {
  try {
    const drivers = await User.find({
      role: 'driver',
      isVerified: true,
    }).select('name phone vehicleType licenseNumber location locationCoordinates');

    const driverIds = drivers.map((d) => d._id);

    const activeAssignments = await DriverAssignment.aggregate([
      {
        $match: {
          driverId: { $in: driverIds },
          status: { $in: ['Assigned', 'Accepted'] },
        },
      },
      {
        $group: {
          _id: '$driverId',
          activeCount: { $sum: 1 },
          requestIds: { $push: '$requestId' },
        },
      },
    ]);

    const assignmentMap = {};
    activeAssignments.forEach((a) => {
      assignmentMap[a._id.toString()] = {
        activeCount: a.activeCount,
        requestIds: a.requestIds,
      };
    });

    const driversWithAvailability = drivers.map((driver) => {
      const assignmentInfo =
        assignmentMap[driver._id.toString()] || {
          activeCount: 0,
          requestIds: [],
        };

      return {
        driverId: driver._id,
        name: driver.name,
        phone: driver.phone,
        vehicleType: driver.vehicleType,
        licenseNumber: driver.licenseNumber,
        location: driver.location,
        coordinates: driver.locationCoordinates,
        availability: assignmentInfo.activeCount === 0 ? 'available' : 'busy',
        currentAssignedPickups: assignmentInfo.activeCount,
      };
    });

    return res.status(200).json({
      success: true,
      drivers: driversWithAvailability,
    });
  } catch (error) {
    console.error('Get available drivers error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch drivers',
    });
  }
};


// =====================================================
// ASSIGN DRIVER TO REQUEST
// =====================================================

const assignDriver = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { driverId } = req.body;

    if (!driverId) {
      return res.status(400).json({
        success: false,
        message: 'Driver ID is required',
      });
    }

    const request = await CollectionRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Collection request not found',
      });
    }

    const driver = await User.findById(driverId);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    if (driver.role !== 'driver') {
      return res.status(400).json({
        success: false,
        message: 'Selected user is not a driver',
      });
    }

    if (!driver.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Selected driver is not verified',
      });
    }

    if (
      request.assignedDriver &&
      request.assignedDriver.toString() === driverId
    ) {
      return res.status(400).json({
        success: false,
        message: 'This driver is already assigned to this request',
      });
    }

    if (
      request.assignedDriver &&
      request.assignedDriver.toString() !== driverId
    ) {
      return res.status(400).json({
        success: false,
        message: 'A driver is already assigned to this request',
      });
    }

    const activeAssignment = await DriverAssignment.findOne({
      driverId: driverId,
      status: { $in: ['Assigned', 'Accepted'] },
    });

    if (activeAssignment) {
      return res.status(400).json({
        success: false,
        message: 'Selected driver is not available',
      });
    }

    // Create the driver assignment
    const assignment = await DriverAssignment.create({
      requestId: requestId,
      driverId: driverId,
      assignedBy: req.user._id,
      assignedAt: new Date(),
      status: 'Assigned',
    });

    // Update collection request: assign driver + change status to 'accepted'
    request.assignedDriver = driverId;
    request.status = 'accepted';
    request.statusHistory.push({
      status: 'accepted',
      timestamp: new Date(),
      note: `Driver ${driver.name} assigned by manager`,
    });
    await request.save();

    await assignment.populate('assignedBy', 'name email');
    await assignment.populate('driverId', 'name phone vehicleType');
    await request.populate('requester', 'name email phone');
    await request.populate('assignedDriver', 'name phone vehicleType');

    return res.status(200).json({
      success: true,
      message: 'Driver assigned successfully',
      assignment,
      request: {
        _id: request._id,
        status: request.status,
        assignedDriver: request.assignedDriver,
      },
    });
  } catch (error) {
    console.error('Assign driver error:', error);

    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'A driver is already assigned to this request',
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Unable to assign driver',
    });
  }
};


// =====================================================
// WASTE MANAGEMENT
// =====================================================

const WasteWeighIn = require('../models/WasteWeighIn');

/**
 * GET /api/manager/waste/weigh-ins
 * Get all driver weigh-in records (paginated, filterable)
 */
const getWasteWeighIns = async (req, res) => {
  try {
    const { page = 1, limit = 20, startDate, endDate, driverId } = req.query;
    const pageNum = parseInt(page) || 1;
    const limitNum = Math.min(parseInt(limit) || 20, 100);
    const skip = (pageNum - 1) * limitNum;

    const filter = {};
    if (driverId) filter.driver = driverId;
    if (startDate || endDate) {
      filter.recordedAt = {};
      if (startDate) filter.recordedAt.$gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        filter.recordedAt.$lte = end;
      }
    }

    const [weighIns, total] = await Promise.all([
      WasteWeighIn.find(filter)
        .sort({ recordedAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .populate('driver', 'name phone')
        .populate('route', 'routeName zone')
        .lean(),
      WasteWeighIn.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      weighIns,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    console.error('Get waste weigh-ins error:', error);
    return res.status(500).json({ success: false, message: 'Unable to fetch weigh-in records' });
  }
};

/**
 * GET /api/manager/waste/received
 * Get collected CollectionRequests (status=collected) for waste receiving section
 * Also returns weigh-ins so the frontend can display both sources
 */
const getReceivedWaste = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      wasteType,
      processingStatus,
      startDate,
      endDate,
      search,
    } = req.query;
    const pageNum = parseInt(page) || 1;
    const limitNum = Math.min(parseInt(limit) || 20, 100);
    const skip = (pageNum - 1) * limitNum;

    // Only show collected requests (waste physically received at center)
    const filter = { status: 'collected' };
    if (wasteType) filter.wasteType = wasteType;
    if (processingStatus) {
      filter.processingStatus = processingStatus;
    }
    if (startDate || endDate) {
      filter.updatedAt = {};
      if (startDate) filter.updatedAt.$gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        filter.updatedAt.$lte = end;
      }
    }
    if (search) {
      filter.$or = [
        { location: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }

    const [requests, total] = await Promise.all([
      CollectionRequest.find(filter)
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .populate('requester', 'name phone location')
        .populate('assignedDriver', 'name phone')
        .populate('processedBy', 'name')
        .lean(),
      CollectionRequest.countDocuments(filter),
    ]);

    return res.status(200).json({
      success: true,
      requests,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        pages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    console.error('Get received waste error:', error);
    return res.status(500).json({ success: false, message: 'Unable to fetch received waste records' });
  }
};

/**
 * PATCH /api/manager/waste/requests/:requestId/processing
 * Update the processing status of a collected waste request
 */
const updateWasteProcessing = async (req, res) => {
  try {
    const { requestId } = req.params;
    const {
      processingStatus,
      recyclableStatus,
      recycledQuantity,
      disposedQuantity,
    } = req.body;

    const request = await CollectionRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({ success: false, message: 'Collection request not found' });
    }
    if (request.status !== 'collected') {
      return res.status(400).json({ success: false, message: 'Only collected requests can be processed' });
    }

    const receivedWeight = request.collectedQuantity ?? request.estimatedQuantity ?? 0;

    // Validate quantities
    if (recycledQuantity !== undefined && recycledQuantity !== null) {
      const rq = Number(recycledQuantity);
      if (!Number.isFinite(rq) || rq < 0) {
        return res.status(400).json({ success: false, message: 'Recycled quantity must be zero or greater' });
      }
      if (rq > receivedWeight) {
        return res.status(400).json({ success: false, message: 'Recycled quantity cannot exceed received weight' });
      }
      request.recycledQuantity = rq;
    }
    if (disposedQuantity !== undefined && disposedQuantity !== null) {
      const dq = Number(disposedQuantity);
      if (!Number.isFinite(dq) || dq < 0) {
        return res.status(400).json({ success: false, message: 'Disposed quantity must be zero or greater' });
      }
      if (dq > receivedWeight) {
        return res.status(400).json({ success: false, message: 'Disposed quantity cannot exceed received weight' });
      }
      request.disposedQuantity = dq;
    }
    // Cross-field validation
    const totalProcessed = (request.recycledQuantity ?? 0) + (request.disposedQuantity ?? 0);
    if (totalProcessed > receivedWeight) {
      return res.status(400).json({
        success: false,
        message: `Total processed quantity (${totalProcessed} kg) exceeds received weight (${receivedWeight} kg)`,
      });
    }

    const validStatuses = ['received', 'sorted', 'recyclable', 'non_recyclable', 'processed', 'recycled', 'disposed'];
    if (processingStatus && !validStatuses.includes(processingStatus)) {
      return res.status(400).json({ success: false, message: 'Invalid processing status' });
    }
    if (processingStatus) {
      request.processingStatus = processingStatus;
      if (processingStatus === 'sorted') request.sortedAt = new Date();
      if (['processed', 'recycled', 'disposed'].includes(processingStatus)) {
        request.processedAt = new Date();
        request.processedBy = req.user._id;
      }
    }
    if (recyclableStatus !== undefined) {
      request.recyclableStatus = recyclableStatus || null;
    }

    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Processing status updated',
      request: {
        _id: request._id,
        processingStatus: request.processingStatus,
        recyclableStatus: request.recyclableStatus,
        recycledQuantity: request.recycledQuantity,
        disposedQuantity: request.disposedQuantity,
        sortedAt: request.sortedAt,
        processedAt: request.processedAt,
      },
    });
  } catch (error) {
    console.error('Update waste processing error:', error);
    return res.status(500).json({ success: false, message: 'Unable to update processing status' });
  }
};

/**
 * GET /api/manager/waste/reports
 * Aggregate waste data for daily/weekly/monthly reports
 */
const getWasteReports = async (req, res) => {
  try {
    const { period = 'daily' } = req.query;

    const now = new Date();
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);

    let startDate;
    if (period === 'daily') {
      startDate = startOfToday;
    } else if (period === 'weekly') {
      startDate = new Date(startOfToday);
      const dayOfWeek = startDate.getDay();
      const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
      startDate.setDate(startDate.getDate() - daysSinceMonday);
    } else if (period === 'monthly') {
      startDate = new Date(startOfToday.getFullYear(), startOfToday.getMonth(), 1);
    } else {
      startDate = startOfToday;
    }

    // Aggregate collected requests for the period
    const [periodStats, dailyStats, weighInStats, byCategory] = await Promise.all([
      // Period aggregate
      CollectionRequest.aggregate([
        {
          $match: {
            status: 'collected',
            updatedAt: { $gte: startDate },
          },
        },
        {
          $group: {
            _id: null,
            totalReceived: { $sum: { $ifNull: ['$collectedQuantity', '$estimatedQuantity'] } },
            totalRecycled: { $sum: { $ifNull: ['$recycledQuantity', 0] } },
            totalDisposed: { $sum: { $ifNull: ['$disposedQuantity', 0] } },
            recyclableCount: { $sum: { $cond: [{ $eq: ['$recyclableStatus', 'recyclable'] }, 1, 0] } },
            nonRecyclableCount: { $sum: { $cond: [{ $eq: ['$recyclableStatus', 'non_recyclable'] }, 1, 0] } },
            totalRecords: { $sum: 1 },
          },
        },
      ]),
      // Today aggregate
      CollectionRequest.aggregate([
        {
          $match: {
            status: 'collected',
            updatedAt: { $gte: startOfToday },
          },
        },
        {
          $group: {
            _id: null,
            totalReceived: { $sum: { $ifNull: ['$collectedQuantity', '$estimatedQuantity'] } },
            totalRecycled: { $sum: { $ifNull: ['$recycledQuantity', 0] } },
            totalDisposed: { $sum: { $ifNull: ['$disposedQuantity', 0] } },
            totalRecords: { $sum: 1 },
          },
        },
      ]),
      // Weigh-in totals for period (from driver weigh-ins)
      WasteWeighIn.aggregate([
        { $match: { recordedAt: { $gte: startDate } } },
        {
          $group: {
            _id: null,
            organic: { $sum: '$weightsKg.organic' },
            plasticPaper: { $sum: '$weightsKg.plasticPaper' },
            glassOthers: { $sum: '$weightsKg.glassOthers' },
            totalWeighIns: { $sum: 1 },
          },
        },
      ]),
      // By waste category (all time for stats)
      CollectionRequest.aggregate([
        { $match: { status: 'collected' } },
        {
          $group: {
            _id: '$wasteType',
            totalWeight: { $sum: { $ifNull: ['$collectedQuantity', '$estimatedQuantity'] } },
            count: { $sum: 1 },
          },
        },
        { $sort: { totalWeight: -1 } },
      ]),
    ]);

    const period_data = periodStats[0] || { totalReceived: 0, totalRecycled: 0, totalDisposed: 0, recyclableCount: 0, nonRecyclableCount: 0, totalRecords: 0 };
    const today_data = dailyStats[0] || { totalReceived: 0, totalRecycled: 0, totalDisposed: 0, totalRecords: 0 };
    const weighIn_data = weighInStats[0] || { organic: 0, plasticPaper: 0, glassOthers: 0, totalWeighIns: 0 };

    const totalReceived = Number(period_data.totalReceived) || 0;
    const totalRecycled = Number(period_data.totalRecycled) || 0;
    const recyclingPercentage = totalReceived > 0 ? Math.round((totalRecycled / totalReceived) * 100 * 10) / 10 : 0;

    return res.status(200).json({
      success: true,
      period,
      report: {
        // Period data
        totalReceived: totalReceived,
        totalRecycled: totalRecycled,
        totalDisposed: Number(period_data.totalDisposed) || 0,
        recyclableCount: period_data.recyclableCount || 0,
        nonRecyclableCount: period_data.nonRecyclableCount || 0,
        totalRecords: period_data.totalRecords || 0,
        recyclingPercentage,
        // Today data
        today: {
          totalReceived: Number(today_data.totalReceived) || 0,
          totalRecycled: Number(today_data.totalRecycled) || 0,
          totalDisposed: Number(today_data.totalDisposed) || 0,
          totalRecords: today_data.totalRecords || 0,
        },
        // Driver weigh-in totals (from end-of-day forms)
        weighInTotals: {
          organic: Number(weighIn_data.organic) || 0,
          plasticPaper: Number(weighIn_data.plasticPaper) || 0,
          glassOthers: Number(weighIn_data.glassOthers) || 0,
          totalWeighIns: weighIn_data.totalWeighIns || 0,
        },
        // Category breakdown
        byCategory: byCategory.map((c) => ({
          category: c._id || 'other',
          totalWeight: Number(c.totalWeight) || 0,
          count: c.count || 0,
        })),
      },
    });
  } catch (error) {
    console.error('Get waste reports error:', error);
    return res.status(500).json({ success: false, message: 'Unable to generate waste report' });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getDriverLiveLocation,
  getDashboardStats,
  getCollectionRequests,
  getRequestDetails,
  getAvailableDrivers,
  assignDriver,
  getWasteWeighIns,
  getReceivedWaste,
  updateWasteProcessing,
  getWasteReports,
};
