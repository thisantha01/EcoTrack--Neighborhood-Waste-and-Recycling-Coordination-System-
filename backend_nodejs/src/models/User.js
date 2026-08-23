const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    phone: {
      type: String,
      trim: true,
      default: '',
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
    },

    role: {
      type: String,
      required: true,
      enum: [
        'neighbour',
        'restaurant_owner',
        'driver',
        'recycling_manager',
      ],
    },

    // Profile
    profilePicture: {
      type: String,
      default: null,
    },

    bio: {
      type: String,
      default: '',
      maxlength: 300,
    },

    // Location (text for all, map coords for neighbour/restaurant_owner)
    location: {
      type: String,
      default: '',
    },

    locationCoordinates: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },

    // Role-specific
    restaurantName: {
      type: String,
      default: '',
    },

    restaurantAddress: {
      type: String,
      default: '',
    },

    licenseNumber: {
      type: String,
      default: '',
    },

    vehicleType: {
      type: String,
      default: '',
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    otp: {
      type: String,
      default: null,
    },

    otpExpiresAt: {
      type: Date,
      default: null,
    },

    resetOtp: {
      type: String,
      default: null,
    },

    resetOtpExpiresAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  'User',
  userSchema
);