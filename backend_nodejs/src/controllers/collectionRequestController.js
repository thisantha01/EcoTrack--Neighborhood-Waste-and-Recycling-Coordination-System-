const CollectionRequest = require('../models/CollectionRequest');
const UserPoints = require('../models/UserPoints');


// =====================================================
// CREATE COLLECTION REQUEST
// =====================================================

const createRequest = async (req, res) => {
  try {
    const {
      wasteType,
      estimatedQuantity,
      description,
      imageUrl,
      location,
      coordinates,
      preferredDate,
      preferredTime,
    } = req.body;

    if (!wasteType || !estimatedQuantity || !location) {
      return res.status(400).json({
        success: false,
        message: 'Waste type, estimated quantity and location are required',
      });
    }

    const request = await CollectionRequest.create({
      requester: req.user._id,
      wasteType,
      estimatedQuantity,
      description: description || '',
      imageUrl: imageUrl || null,
      location: location.trim(),
      coordinates: coordinates || {},
      preferredDate: preferredDate || null,
      preferredTime: preferredTime || null,
      status: 'requested',
      statusHistory: [{ status: 'requested', note: 'Request created' }],
    });

    await request.populate('requester', 'name profilePicture role');

    // Award points for creating a request
    try {
      await UserPoints.findOneAndUpdate(
        { user: req.user._id },
        { $inc: { points: 5 } },
        { upsert: true }
      );
    } catch (err) {
      console.error('Award points error:', err);
    }

    return res.status(201).json({
      success: true,
      message: 'Collection request created successfully',
      request,
    });

  } catch (error) {
    console.error('Create request error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to create collection request',
    });
  }
};


// =====================================================
// GET MY REQUESTS
// =====================================================

const getMyRequests = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = { requester: req.user._id };
    if (status) filter.status = status;

    const requests = await CollectionRequest.find(filter)
      .sort({ createdAt: -1 })
      .populate('requester', 'name profilePicture role')
      .populate('assignedDriver', 'name profilePicture');

    return res.status(200).json({
      success: true,
      requests,
    });

  } catch (error) {
    console.error('Get my requests error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch requests',
    });
  }
};


// =====================================================
// GET ALL REQUESTS (for drivers / admin)
// =====================================================

const getAllRequests = async (req, res) => {
  try {
    const { status, wasteType } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (wasteType) filter.wasteType = wasteType;

    const requests = await CollectionRequest.find(filter)
      .sort({ createdAt: -1 })
      .populate('requester', 'name profilePicture role')
      .populate('assignedDriver', 'name profilePicture');

    return res.status(200).json({
      success: true,
      requests,
    });

  } catch (error) {
    console.error('Get all requests error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch requests',
    });
  }
};


// =====================================================
// GET SINGLE REQUEST
// =====================================================

const getRequest = async (req, res) => {
  try {
    const request = await CollectionRequest.findById(req.params.id)
      .populate('requester', 'name profilePicture role phone')
      .populate('assignedDriver', 'name profilePicture');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Request not found',
      });
    }

    return res.status(200).json({
      success: true,
      request,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch request',
    });
  }
};


// =====================================================
// UPDATE STATUS (drivers / recycling_manager)
// =====================================================

const updateStatus = async (req, res) => {
  try {
    const { status, note, assignedDriver } = req.body;

    const validStatuses = ['requested', 'accepted', 'scheduled', 'collected', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    const request = await CollectionRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Request not found',
      });
    }

    // Validate status transitions
    const validTransitions = {
      requested: ['accepted', 'cancelled'],
      accepted: ['scheduled', 'cancelled'],
      scheduled: ['collected', 'cancelled'],
      collected: [],
      cancelled: [],
    };

    if (!validTransitions[request.status].includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot transition from "${request.status}" to "${status}"`,
      });
    }

    request.status = status;
    request.statusHistory.push({
      status,
      note: note || `Status updated to ${status}`,
    });

    if (assignedDriver) {
      request.assignedDriver = assignedDriver;
    }

    await request.save();
    await request.populate('requester', 'name profilePicture role');
    await request.populate('assignedDriver', 'name profilePicture');

    return res.status(200).json({
      success: true,
      message: `Request status updated to "${status}"`,
      request,
    });

  } catch (error) {
    console.error('Update status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to update request status',
    });
  }
};


// =====================================================
// CANCEL REQUEST (requester only, if still "requested")
// =====================================================

const cancelRequest = async (req, res) => {
  try {
    const request = await CollectionRequest.findById(req.params.id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Request not found',
      });
    }

    // Only the requester can cancel
    if (request.requester.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorised to cancel this request',
      });
    }

    // Can only cancel if not yet accepted
    if (!['requested', 'accepted'].includes(request.status)) {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a request that is already scheduled or collected',
      });
    }

    request.status = 'cancelled';
    request.statusHistory.push({
      status: 'cancelled',
      note: 'Cancelled by requester',
    });

    await request.save();
    await request.populate('requester', 'name profilePicture role');

    return res.status(200).json({
      success: true,
      message: 'Request cancelled',
      request,
    });

  } catch (error) {
    console.error('Cancel request error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to cancel request',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  createRequest,
  getMyRequests,
  getAllRequests,
  getRequest,
  updateStatus,
  cancelRequest,
};
