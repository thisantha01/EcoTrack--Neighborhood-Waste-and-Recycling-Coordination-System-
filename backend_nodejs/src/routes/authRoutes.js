const express = require('express');

const {
  register,
  verifyOtp,
  resendOtp,
  login,
  getMe,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
} = require('../controllers/authController');

const {
  protect,
} = require('../middleware/authMiddleware');

const router = express.Router();


// Register
router.post(
  '/register',
  register
);


// Verify registration OTP
router.post(
  '/verify-otp',
  verifyOtp
);


// Resend registration OTP
router.post(
  '/resend-otp',
  resendOtp
);


// Login
router.post(
  '/login',
  login
);


// Get logged-in user
router.get(
  '/me',
  protect,
  getMe
);


// Forgot password
router.post(
  '/forgot-password',
  forgotPassword
);


// Verify password reset OTP
router.post(
  '/verify-reset-otp',
  verifyResetOtp
);


// Reset password
router.post(
  '/reset-password',
  resetPassword
);


module.exports = router;