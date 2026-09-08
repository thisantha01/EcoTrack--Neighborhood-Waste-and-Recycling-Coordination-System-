require('dotenv').config();

const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const connectDB = require('../src/config/db');
const Route = require('../src/models/Route');
const User = require('../src/models/User');

const defaultRoutes = [
  { routeName: 'Route A', zone: 'Colombo 05', operatingDays: ['Monday', 'Thursday'], lat: 6.8897, lng: 79.8774 },
  { routeName: 'Route B', zone: 'Colombo 07', operatingDays: ['Tuesday', 'Friday'], lat: 6.9067, lng: 79.8616 },
  { routeName: 'Route C', zone: 'Nugegoda', operatingDays: ['Wednesday', 'Saturday'], lat: 6.8649, lng: 79.8997 },
  { routeName: 'Route D', zone: 'Maharagama', operatingDays: ['Monday', 'Wednesday'], lat: 6.8480, lng: 79.9265 },
  { routeName: 'Route E', zone: 'Kottawa', operatingDays: ['Tuesday', 'Thursday'], lat: 6.8010, lng: 79.9227 },
];

const seedRoutes = async () => {
  await connectDB();
  const password = await bcrypt.hash(process.env.SEED_DRIVER_PASSWORD || 'ChangeMe123!', 12);

  for (let index = 0; index < defaultRoutes.length; index += 1) {
    const routeData = defaultRoutes[index];
    const driverEmail = `driver${index + 1}@ecotrack.local`;
    const driver = await User.findOneAndUpdate(
      { email: driverEmail },
      {
        $setOnInsert: {
          name: `Driver ${index + 1}`,
          email: driverEmail,
          password,
          role: 'driver',
          isVerified: true,
        },
      },
      { upsert: true, new: true }
    );

    await Route.findOneAndUpdate(
      { routeName: routeData.routeName },
      {
        $set: {
          zone: routeData.zone,
          description: `Permanent collection route for ${routeData.zone}`,
          assignedLocations: [routeData.zone],
          areaCoordinates: { lat: routeData.lat, lng: routeData.lng },
          assignedDriver: driver._id,
          operatingDays: routeData.operatingDays,
          status: 'Active',
          routeStatus: 'Active',
        },
        $setOnInsert: { routeStops: [], stops: [] },
      },
      { upsert: true, new: true }
    );
  }

  console.log('Default EcoTrack routes seeded successfully.');
  await mongoose.disconnect();
};

seedRoutes().catch(async (error) => {
  console.error('Route seeding failed:', error);
  await mongoose.disconnect();
  process.exit(1);
});
