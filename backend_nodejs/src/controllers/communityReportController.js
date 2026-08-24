const CommunityReport = require('../models/CommunityReport');
const UserPoints = require('../models/UserPoints');


// =====================================================
// GET REPORTS
// =====================================================

const getReports = async (req, res) => {
  try {
    const { status, type } = req.query;
    const filter = {};
    if (status) filter.status = status;
    if (type) filter.type = type;

    const reports = await CommunityReport.find(filter)
      .sort({ createdAt: -1 })
      .populate('reporter', 'name profilePicture role')
      .populate('additionalInfo.user', 'name profilePicture')
      .populate('upvotes', 'name');

    return res.status(200).json({
      success: true,
      reports,
    });

  } catch (error) {
    console.error('Get reports error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch reports',
    });
  }
};


// =====================================================
// GET SINGLE REPORT
// =====================================================

const getReport = async (req, res) => {
  try {
    const report = await CommunityReport.findById(req.params.id)
      .populate('reporter', 'name profilePicture role')
      .populate('additionalInfo.user', 'name profilePicture')
      .populate('upvotes', 'name');

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found',
      });
    }

    return res.status(200).json({
      success: true,
      report,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch report',
    });
  }
};


// =====================================================
// CREATE REPORT
// =====================================================

const createReport = async (req, res) => {
  try {
    const {
      title,
      description,
      location,
      coordinates,
      imageUrl,
      type,
    } = req.body;

    if (!title || !description || !location) {
      return res.status(400).json({
        success: false,
        message: 'Title, description and location are required',
      });
    }

    const report = await CommunityReport.create({
      reporter: req.user._id,
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      coordinates: coordinates || {},
      imageUrl: imageUrl || null,
      type: type || 'illegal_dumping',
      statusHistory: [{ status: 'open', note: 'Report submitted' }],
    });

    await report.populate('reporter', 'name profilePicture role');

    // Award points
    await UserPoints.findOneAndUpdate(
      { user: req.user._id },
      { $inc: { points: 10, reportsSubmitted: 1 } },
      { upsert: true }
    );

    return res.status(201).json({
      success: true,
      message: 'Report submitted successfully',
      report,
    });

  } catch (error) {
    console.error('Create report error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to submit report',
    });
  }
};


// =====================================================
// TOGGLE UPVOTE
// =====================================================

const toggleUpvote = async (req, res) => {
  try {
    const report = await CommunityReport.findById(req.params.id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found',
      });
    }

    const userId = req.user._id;
    const upvoted = report.upvotes.some(
      (id) => id.toString() === userId.toString()
    );

    if (upvoted) {
      report.upvotes.pull(userId);
    } else {
      report.upvotes.push(userId);
    }

    await report.save();

    return res.status(200).json({
      success: true,
      upvoted: !upvoted,
      upvoteCount: report.upvotes.length,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to update upvote',
    });
  }
};


// =====================================================
// ADD ADDITIONAL INFO
// =====================================================

const addAdditionalInfo = async (req, res) => {
  try {
    const { text, imageUrl } = req.body;

    if (!text && !imageUrl) {
      return res.status(400).json({
        success: false,
        message: 'Text or image is required',
      });
    }

    const report = await CommunityReport.findById(req.params.id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found',
      });
    }

    report.additionalInfo.push({
      user: req.user._id,
      text: text || '',
      imageUrl: imageUrl || null,
    });

    await report.save();
    await report.populate('additionalInfo.user', 'name profilePicture');

    return res.status(201).json({
      success: true,
      info: report.additionalInfo[report.additionalInfo.length - 1],
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to add information',
    });
  }
};


// =====================================================
// UPDATE STATUS (admin/recycling_manager)
// =====================================================

const updateReportStatus = async (req, res) => {
  try {
    const { status } = req.body;

    const validStatuses = ['open', 'in_progress', 'resolved'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    const report = await CommunityReport.findById(req.params.id);

    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Report not found',
      });
    }

    report.status = status;
    report.statusHistory.push({
      status,
      note: req.body.note || `Status updated to ${status}`,
    });

    await report.save();
    await report.populate('reporter', 'name profilePicture');

    return res.status(200).json({
      success: true,
      message: 'Report status updated',
      report,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to update report',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getReports,
  getReport,
  createReport,
  toggleUpvote,
  addAdditionalInfo,
  updateReportStatus,
};
