require('dotenv').config();

const dns = require('dns');

dns.setServers([
  '1.1.1.1',
  '8.8.8.8',
]);

const express = require('express');
const cors = require('cors');

const connectDB = require('./src/config/db');

const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const communityPostRoutes = require('./src/routes/communityPostRoutes');
const cleanupEventRoutes = require('./src/routes/cleanupEventRoutes');
const announcementRoutes = require('./src/routes/announcementRoutes');
const communityReportRoutes = require('./src/routes/communityReportRoutes');
const engagementRoutes = require('./src/routes/engagementRoutes');
const managerRoutes = require('./src/routes/managerRoutes');
const collectionRequestRoutes = require('./src/routes/collectionRequestRoutes');


const app = express();

const PORT = process.env.PORT || 5000;


// =====================================================
// MIDDLEWARE
// =====================================================

app.use(cors());

app.use(express.json());

app.use(
  express.urlencoded({
    extended: true,
  })
);


// =====================================================
// HEALTH CHECK
// =====================================================

app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Waste Management API is running',
  });
});


// =====================================================
// AUTH ROUTES
// =====================================================

app.use(
  '/api/auth',
  authRoutes
);

app.use('/api/profile', profileRoutes);

app.use('/api/community/posts', communityPostRoutes);

app.use('/api/community/events', cleanupEventRoutes);

app.use('/api/community/announcements', announcementRoutes);

app.use('/api/community/reports', communityReportRoutes);

app.use('/api/community/engagement', engagementRoutes);

app.use('/api/collection-requests', collectionRequestRoutes);
app.use('/api/manager', managerRoutes);


// =====================================================
// 404 HANDLER
// =====================================================

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});


// =====================================================
// START SERVER
// =====================================================

const startServer = async () => {
  try {
    await connectDB();

    app.listen(
      PORT,
      '0.0.0.0',
      () => {
        console.log(
          `Server running on port ${PORT}`
        );

        console.log(
          `API: http://localhost:${PORT}`
        );
      }
    );

  } catch (error) {
    console.error(
      'Server startup failed:',
      error.message
    );

    process.exit(1);
  }
};

startServer();