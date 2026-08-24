const Route = require('../models/route.model');

// Create route & Assign driver with waste requests
exports.createAndAssignRoute = async (req, res) => {
  try {
    const { routeName, driverId, scheduledDate, pickupRequests } = req.body;

    const newRoute = new Route({
      routeName,
      driverId,
      scheduledDate,
      pickupRequests
    });

    await newRoute.save();
    res.status(201).json({ message: "Route assigned successfully", route: newRoute });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};