const CleanupEvent = require('../models/CleanupEvent');
const UserPoints = require('../models/UserPoints');


// Helper to award points
const awardPoints = async (userId, points, field) => {
  try {
    const update = { $inc: { points } };
    if (field) update.$inc[field] = 1;

    const userPoints = await UserPoints.findOneAndUpdate(
      { user: userId },
      update,
      { upsert: true, new: true }
    );

    let level = 'bronze';
    if (userPoints.points >= 500) level = 'platinum';
    else if (userPoints.points >= 200) level = 'gold';
    else if (userPoints.points >= 100) level = 'silver';

    await UserPoints.findOneAndUpdate(
      { user: userId },
      { level }
    );
  } catch (err) {
    console.error('Award points error:', err);
  }
};


// =====================================================
// GET EVENTS
// =====================================================

const getEvents = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const events = await CleanupEvent.find(filter)
      .sort({ scheduledAt: 1 })
      .populate('organizer', 'name profilePicture role')
      .populate('participants', 'name profilePicture');

    return res.status(200).json({
      success: true,
      events,
    });

  } catch (error) {
    console.error('Get events error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch events',
    });
  }
};


// =====================================================
// GET SINGLE EVENT
// =====================================================

const getEvent = async (req, res) => {
  try {
    const event = await CleanupEvent.findById(req.params.id)
      .populate('organizer', 'name profilePicture role')
      .populate('participants', 'name profilePicture role');

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    return res.status(200).json({
      success: true,
      event,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch event',
    });
  }
};


// =====================================================
// CREATE EVENT
// =====================================================

const createEvent = async (req, res) => {
  try {
    const {
      title,
      description,
      location,
      coordinates,
      scheduledAt,
      maxParticipants,
    } = req.body;

    if (!title || !location || !scheduledAt) {
      return res.status(400).json({
        success: false,
        message: 'Title, location and scheduledAt are required',
      });
    }

    const event = await CleanupEvent.create({
      title: title.trim(),
      description: description || '',
      location: location.trim(),
      coordinates: coordinates || {},
      scheduledAt: new Date(scheduledAt),
      organizer: req.user._id,
      participants: [req.user._id],
      maxParticipants: maxParticipants || 50,
    });

    await event.populate('organizer', 'name profilePicture role');

    await awardPoints(req.user._id, 20, null);

    return res.status(201).json({
      success: true,
      message: 'Cleanup event created',
      event,
    });

  } catch (error) {
    console.error('Create event error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to create event',
    });
  }
};


// =====================================================
// JOIN / LEAVE EVENT
// =====================================================

const toggleJoin = async (req, res) => {
  try {
    const event = await CleanupEvent.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    if (event.status !== 'upcoming') {
      return res.status(400).json({
        success: false,
        message: 'Cannot join an event that is not upcoming',
      });
    }

    const userId = req.user._id;
    const joined = event.participants.some(
      (p) => p.toString() === userId.toString()
    );

    if (joined) {
      event.participants.pull(userId);
    } else {
      if (event.participants.length >= event.maxParticipants) {
        return res.status(400).json({
          success: false,
          message: 'Event is full',
        });
      }
      event.participants.push(userId);
      await awardPoints(userId, 10, 'eventsJoined');
    }

    await event.save();

    return res.status(200).json({
      success: true,
      joined: !joined,
      participantsCount: event.participants.length,
    });

  } catch (error) {
    console.error('Toggle join error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to update participation',
    });
  }
};


// =====================================================
// UPDATE EVENT STATUS
// =====================================================

const updateEventStatus = async (req, res) => {
  try {
    const { status, wasteCollected, wasteRecycled } = req.body;

    const validStatuses = ['upcoming', 'ongoing', 'completed', 'cancelled'];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    const event = await CleanupEvent.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    if (event.organizer.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Only the organizer can update event status',
      });
    }

    event.status = status;
    if (wasteCollected !== undefined) event.wasteCollected = wasteCollected;
    if (wasteRecycled !== undefined) event.wasteRecycled = wasteRecycled;

    await event.save();

    // Award points to participants on completion
    if (status === 'completed') {
      for (const participantId of event.participants) {
        await UserPoints.findOneAndUpdate(
          { user: participantId },
          { $inc: { points: 15, totalWasteCollected: wasteCollected || 0 } },
          { upsert: true }
        );
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Event status updated',
      event,
    });

  } catch (error) {
    console.error('Update event status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to update event',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getEvents,
  getEvent,
  createEvent,
  toggleJoin,
  updateEventStatus,
};
