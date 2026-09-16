const CollectionRequest = require('../models/CollectionRequest');
const DriverAssignment = require('../models/DriverAssignment');
const User = require('../models/User');


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

    const requests = await CollectionRequest.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .populate('requester', 'name email phone location')
      .populate('assignedDriver', 'name phone vehicleType');

    const total = await CollectionRequest.countDocuments(filter);

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
// EXPORT
// =====================================================

module.exports = {
  getDashboardStats,
  getCollectionRequests,
  getRequestDetails,
  getAvailableDrivers,
  assignDriver,
};
