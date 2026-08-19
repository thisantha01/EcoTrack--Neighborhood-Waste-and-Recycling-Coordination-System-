const bcrypt = require('bcryptjs');

const User = require('../models/User');

const generateOtp = require('../utils/generateOtp');

const generateToken = require('../utils/generateToken');

const {
  sendVerificationOtp,
  sendPasswordResetOtp,
} = require('../services/emailService');


// =====================================================
// REGISTER
// =====================================================

const register = async (req, res) => {
  try {
    const {
      name,
      email,
      phone,
      password,
      role,
    } = req.body;

    // Validate required fields
    if (
      !name ||
      !email ||
      !password ||
      !role
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Name, email, password and role are required',
      });
    }

    // Validate role
    const allowedRoles = [
      'neighbour',
      'restaurant_owner',
      'driver',
      'recycling_manager',
    ];

    if (!allowedRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid role',
      });
    }

    // Check existing user
    let user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (user) {
      if (user.isVerified) {
        return res.status(409).json({
          success: false,
          message:
            'An account with this email already exists',
        });
      }

      // Existing but not verified
      const otp = generateOtp();

      user.otp = otp;

      user.otpExpiresAt =
        new Date(
          Date.now() + 10 * 60 * 1000
        );

      await user.save();

      await sendVerificationOtp(
        user.email,
        user.name,
        otp
      );

      return res.status(200).json({
        success: true,
        message:
          'Account already exists but is not verified. A new OTP has been sent.',
        requiresVerification: true,
      });
    }

    // Hash password
    const hashedPassword =
      await bcrypt.hash(password, 12);

    // Generate OTP
    const otp = generateOtp();

    // Create user
    user = await User.create({
      name,
      email: email.toLowerCase(),
      phone: phone || '',
      password: hashedPassword,
      role,
      isVerified: false,
      otp,
      otpExpiresAt:
        new Date(
          Date.now() + 10 * 60 * 1000
        ),
    });

    // Send email
    try {
      await sendVerificationOtp(
        user.email,
        user.name,
        otp
      );
    } catch (emailError) {
      // Delete account if email failed
      await User.findByIdAndDelete(
        user._id
      );

      console.error(
        'Email sending failed:',
        emailError.message
      );

      return res.status(500).json({
        success: false,
        message:
          'Unable to send verification email',
      });
    }

    return res.status(201).json({
      success: true,
      message:
        'Registration successful. Please check your email for the OTP.',
      requiresVerification: true,
      email: user.email,
    });

  } catch (error) {
    console.error(
      'Register error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Server error during registration',
    });
  }
};


// =====================================================
// VERIFY REGISTRATION OTP
// =====================================================

const verifyOtp = async (req, res) => {
  try {
    const {
      email,
      otp,
    } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message:
          'Email and OTP are required',
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message:
          'Account is already verified',
      });
    }

    if (!user.otp) {
      return res.status(400).json({
        success: false,
        message:
          'No OTP found. Please request a new OTP.',
      });
    }

    if (
      user.otpExpiresAt < new Date()
    ) {
      return res.status(400).json({
        success: false,
        message:
          'OTP has expired. Please request a new OTP.',
      });
    }

    if (user.otp !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP',
      });
    }

    user.isVerified = true;
    user.otp = null;
    user.otpExpiresAt = null;

    await user.save();

    const token = generateToken(user);

    return res.status(200).json({
      success: true,
      message:
        'Email verified successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isVerified: user.isVerified,
      },
    });

  } catch (error) {
    console.error(
      'Verify OTP error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Server error during OTP verification',
    });
  }
};


// =====================================================
// RESEND OTP
// =====================================================

const resendOtp = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required',
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (user.isVerified) {
      return res.status(400).json({
        success: false,
        message:
          'Account is already verified',
      });
    }

    const otp = generateOtp();

    user.otp = otp;

    user.otpExpiresAt =
      new Date(
        Date.now() + 10 * 60 * 1000
      );

    await user.save();

    await sendVerificationOtp(
      user.email,
      user.name,
      otp
    );

    return res.status(200).json({
      success: true,
      message:
        'A new OTP has been sent to your email',
    });

  } catch (error) {
    console.error(
      'Resend OTP error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Unable to resend OTP',
    });
  }
};


// =====================================================
// LOGIN
// =====================================================

const login = async (req, res) => {
  try {
    const {
      email,
      password,
    } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message:
          'Email and password are required',
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message:
          'Invalid email or password',
      });
    }

    if (!user.isVerified) {
      return res.status(403).json({
        success: false,
        message:
          'Please verify your email before logging in',
        requiresVerification: true,
      });
    }

    const passwordMatch =
      await bcrypt.compare(
        password,
        user.password
      );

    if (!passwordMatch) {
      return res.status(401).json({
        success: false,
        message:
          'Invalid email or password',
      });
    }

    const token =
      generateToken(user);

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      token,

      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isVerified: user.isVerified,
      },
    });

  } catch (error) {
    console.error(
      'Login error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Server error during login',
    });
  }
};


// =====================================================
// GET CURRENT USER
// =====================================================

const getMe = async (req, res) => {
  try {
    return res.status(200).json({
      success: true,

      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        phone: req.user.phone,
        role: req.user.role,
        isVerified: req.user.isVerified,
      },
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message:
        'Unable to retrieve user',
    });
  }
};


// =====================================================
// FORGOT PASSWORD
// =====================================================

const forgotPassword = async (
  req,
  res
) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required',
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          'No account found with this email',
      });
    }

    if (!user.isVerified) {
      return res.status(400).json({
        success: false,
        message:
          'Please verify your email first',
      });
    }

    const otp = generateOtp();

    user.resetOtp = otp;

    user.resetOtpExpiresAt =
      new Date(
        Date.now() + 10 * 60 * 1000
      );

    await user.save();

    await sendPasswordResetOtp(
      user.email,
      user.name,
      otp
    );

    return res.status(200).json({
      success: true,
      message:
        'Password reset OTP has been sent to your email',
    });

  } catch (error) {
    console.error(
      'Forgot password error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Unable to process password reset request',
    });
  }
};


// =====================================================
// VERIFY PASSWORD RESET OTP
// =====================================================

const verifyResetOtp = async (
  req,
  res
) => {
  try {
    const {
      email,
      otp,
    } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message:
          'Email and OTP are required',
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          'User not found',
      });
    }

    if (!user.resetOtp) {
      return res.status(400).json({
        success: false,
        message:
          'No reset OTP found',
      });
    }

    if (
      user.resetOtpExpiresAt < new Date()
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Reset OTP has expired',
      });
    }

    if (user.resetOtp !== otp) {
      return res.status(400).json({
        success: false,
        message:
          'Invalid reset OTP',
      });
    }

    return res.status(200).json({
      success: true,
      message:
        'OTP verified successfully',
    });

  } catch (error) {
    console.error(
      'Verify reset OTP error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Server error',
    });
  }
};


// =====================================================
// RESET PASSWORD
// =====================================================

const resetPassword = async (
  req,
  res
) => {
  try {
    const {
      email,
      otp,
      newPassword,
    } = req.body;

    if (
      !email ||
      !otp ||
      !newPassword
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Email, OTP and new password are required',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message:
          'Password must be at least 6 characters',
      });
    }

    const user = await User.findOne({
      email: email.toLowerCase(),
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message:
          'User not found',
      });
    }

    if (!user.resetOtp) {
      return res.status(400).json({
        success: false,
        message:
          'No reset OTP found',
      });
    }

    if (
      user.resetOtpExpiresAt < new Date()
    ) {
      return res.status(400).json({
        success: false,
        message:
          'Reset OTP has expired',
      });
    }

    if (user.resetOtp !== otp) {
      return res.status(400).json({
        success: false,
        message:
          'Invalid reset OTP',
      });
    }

    user.password =
      await bcrypt.hash(
        newPassword,
        12
      );

    user.resetOtp = null;
    user.resetOtpExpiresAt = null;

    await user.save();

    return res.status(200).json({
      success: true,
      message:
        'Password reset successfully',
    });

  } catch (error) {
    console.error(
      'Reset password error:',
      error
    );

    return res.status(500).json({
      success: false,
      message:
        'Unable to reset password',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  register,
  verifyOtp,
  resendOtp,
  login,
  getMe,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
};