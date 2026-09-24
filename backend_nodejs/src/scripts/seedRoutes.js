require('dotenv').config();

const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const connectDB = require('../src/config/db');
const Route = require('../src/models/Route');
const User = require('../src/models/User');

const defaultRoutes = [
  {
    routeName: 'Route M - Malabe Campus Loop',
    zone: 'Malabe',
    operatingDays: ['Monday', 'Wednesday', 'Friday'],
    lat: 6.9061,
    lng: 79.9696,
    stops: [
      { address: 'SLIIT Campus, New Kandy Rd, Malabe', location: { lat: 6.9147, lng: 79.9733 }, sequenceOrder: 1 },
      { address: 'Horizon Campus / Knowledge City, Malabe', location: { lat: 6.9110, lng: 79.9805 }, sequenceOrder: 2 },
      { address: 'Kaduwela Road - Pittugala Junction', location: { lat: 6.9090, lng: 79.9660 }, sequenceOrder: 3 },
      { address: 'Malabe Town Center / Kaduwela Rd Junction', location: { lat: 6.9042, lng: 79.9572 }, sequenceOrder: 4 },
      { address: 'Chandrika Kumaratunga Mawatha, Malabe', location: { lat: 6.9015, lng: 79.9720 }, sequenceOrder: 5 },
    ],
  },
  { routeName: 'Route A', zone: 'Colombo 05', operatingDays: ['Monday', 'Thursday'], lat: 6.8897, lng: 79.8774, stops: [] },
  { routeName: 'Route B', zone: 'Colombo 07', operatingDays: ['Tuesday', 'Friday'], lat: 6.9067, lng: 79.8616, stops: [] },
  { routeName: 'Route C', zone: 'Nugegoda', operatingDays: ['Wednesday', 'Saturday'], lat: 6.8649, lng: 79.8997, stops: [] },
  { routeName: 'Route D', zone: 'Maharagama', operatingDays: ['Monday', 'Wednesday'], lat: 6.8480, lng: 79.9265, stops: [] },
  { routeName: 'Route E', zone: 'Kottawa', operatingDays: ['Tuesday', 'Thursday'], lat: 6.8010, lng: 79.9227, stops: [] },
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
          routeStops: routeData.stops || [],
          stops: routeData.stops || [],
        },
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
