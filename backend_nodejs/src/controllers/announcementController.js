const Announcement = require('../models/Announcement');


// =====================================================
// GET ANNOUNCEMENTS
// =====================================================

const getAnnouncements = async (req, res) => {
  try {
    const { type } = req.query;
    const filter = {};
    if (type) filter.type = type;

    const announcements = await Announcement.find(filter)
      .sort({ createdAt: -1 })
      .populate('author', 'name profilePicture role');

    return res.status(200).json({
      success: true,
      announcements,
    });

  } catch (error) {
    console.error('Get announcements error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch announcements',
    });
  }
};


// =====================================================
// CREATE ANNOUNCEMENT
// =====================================================

const createAnnouncement = async (req, res) => {
  try {
    const {
      title,
      content,
      type,
      scheduledAt,
      location,
      targetRoles,
    } = req.body;

    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Title and content are required',
      });
    }

    const announcement = await Announcement.create({
      author: req.user._id,
      title: title.trim(),
      content: content.trim(),
      type: type || 'announcement',
      scheduledAt: scheduledAt ? new Date(scheduledAt) : null,
      location: location || '',
      targetRoles: targetRoles || ['all'],
    });

    await announcement.populate('author', 'name profilePicture role');

    return res.status(201).json({
      success: true,
      message: 'Announcement created',
      announcement,
    });

  } catch (error) {
    console.error('Create announcement error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to create announcement',
    });
  }
};


// =====================================================
// DELETE ANNOUNCEMENT
// =====================================================

const deleteAnnouncement = async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);

    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: 'Announcement not found',
      });
    }

    if (announcement.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorised',
      });
    }

    await announcement.deleteOne();

    return res.status(200).json({
      success: true,
      message: 'Announcement deleted',
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to delete announcement',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getAnnouncements,
  createAnnouncement,
  deleteAnnouncement,
};
