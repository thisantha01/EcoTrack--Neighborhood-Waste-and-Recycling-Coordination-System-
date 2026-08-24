const CollectionRequest = require('../models/CollectionRequest');


// =====================================================
// CREATE COLLECTION REQUEST
// =====================================================

const createCollectionRequest = async (req, res) => {
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

    // Validate required fields
    if (!wasteType) {
      return res.status(400).json({
        success: false,
        message: 'Waste type is required',
      });
    }

    if (estimatedQuantity === undefined || estimatedQuantity === null) {
      return res.status(400).json({
        success: false,
        message: 'Estimated quantity is required',
      });
    }

    if (!location) {
      return res.status(400).json({
        success: false,
        message: 'Pickup location is required',
      });
    }

    const request = await CollectionRequest.create({
      requester: req.user._id,
      wasteType,
      estimatedQuantity,
      description: description || '',
      imageUrl: imageUrl || null,
      location,
      coordinates: coordinates || {},
      preferredDate: preferredDate ? new Date(preferredDate) : null,
      preferredTime: preferredTime || '',
      status: 'requested',
      statusHistory: [
        {
          status: 'requested',
          timestamp: new Date(),
          note: 'Collection request submitted',
        },
      ],
    });

    return res.status(201).json({
      success: true,
      message: 'Collection request created successfully',
      request,
    });
  } catch (error) {
    console.error('Create collection request error:', error);

    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        message: messages.join(', '),
      });
    }

    return res.status(500).json({
      success: false,
      message: 'Unable to create collection request',
    });
  }
};


// =====================================================
// GET MY COLLECTION REQUESTS
// =====================================================

const getMyCollectionRequests = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;

    const filter = { requester: req.user._id };

    if (status) {
      filter.status = status;
    }

    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 20;
    const skip = (pageNum - 1) * limitNum;

    const requests = await CollectionRequest.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum)
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
    console.error('Get my collection requests error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch collection requests',
    });
  }
};


// =====================================================
// GET MY SINGLE REQUEST
// =====================================================

const getMyCollectionRequest = async (req, res) => {
  try {
    const request = await CollectionRequest.findOne({
      _id: req.params.id,
      requester: req.user._id,
    }).populate('assignedDriver', 'name phone vehicleType');

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Collection request not found',
      });
    }

    return res.status(200).json({
      success: true,
      request,
    });
  } catch (error) {
    console.error('Get my collection request error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch collection request',
    });
  }
};


// =====================================================
// CANCEL MY REQUEST
// =====================================================

const cancelCollectionRequest = async (req, res) => {
  try {
    const request = await CollectionRequest.findOne({
      _id: req.params.id,
      requester: req.user._id,
    });

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Collection request not found',
      });
    }

    if (request.status === 'collected') {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel a collected request',
      });
    }

    if (request.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Request is already cancelled',
      });
    }

    request.status = 'cancelled';
    request.statusHistory.push({
      status: 'cancelled',
      timestamp: new Date(),
      note: 'Cancelled by requester',
    });
    await request.save();

    return res.status(200).json({
      success: true,
      message: 'Request cancelled',
      request,
    });
  } catch (error) {
    console.error('Cancel collection request error:', error);
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
  createCollectionRequest,
  getMyCollectionRequests,
  getMyCollectionRequest,
  cancelCollectionRequest,
};
