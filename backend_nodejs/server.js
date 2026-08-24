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