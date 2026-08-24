const Pickup = require('../models/pickup');
const User = require('../models/User'); // Adjust path to your User model if needed

/**
 * @desc    Get dashboard overview metrics and next scheduled pickup
 * @route   GET /api/driver/dashboard
 * @access  Private (Driver only)
 */
exports.getDashboardOverview = async (req, res) => {
  try {
    const driverId = req.user._id;

    // Fetch latest availability status of the driver
    const driver = await User.findById(driverId).select('isAvailable name');
    if (!driver) {
      return res.status(404).json({ message: 'Driver account not found' });
    }

    // Set start and end boundaries for "Today"
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    // Filter pickups assigned to this driver created/scheduled today
    const todayQuery = {
      driverId,
      createdAt: { $gte: startOfDay, $lte: endOfDay },
    };

    const totalPickups = await Pickup.countDocuments(todayQuery);
    const completedPickups = await Pickup.countDocuments({
      ...todayQuery,
      status: 'completed',
    });
    const remainingPickups = await Pickup.countDocuments({
      ...todayQuery,
      status: { $in: ['scheduled', 'accepted'] },
    });

    // Get the next active pickup ('accepted' takes priority, otherwise next 'scheduled')
    let nextPickup = await Pickup.findOne({
      driverId,
      status: 'accepted',
    }).sort({ createdAt: 1 });

    if (!nextPickup) {
      nextPickup = await Pickup.findOne({
        driverId,
        status: 'scheduled',
      }).sort({ createdAt: 1 });
    }

    res.status(200).json({
      success: true,
      isAvailable: driver.isAvailable ?? true,
      metrics: {
        totalPickups,
        completedPickups,
        remainingPickups,
      },
      nextPickup: nextPickup || null,
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

    const validStatuses = ['scheduled', 'accepted', 'completed', 'cancelled'];
    if (!status || !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status provided',
      });
    }

    const pickup = await Pickup.findOne({ _id: id, driverId });
    if (!pickup) {
      return res.status(404).json({
        success: false,
        message: 'Pickup task not found or unauthorized',
      });
    }

    pickup.status = status;
    if (status === 'completed') {
      pickup.completedAt = new Date();
    }

    await pickup.save();

    res.status(200).json({
      success: true,
      message: `Pickup status updated to ${status}`,
      pickup,
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