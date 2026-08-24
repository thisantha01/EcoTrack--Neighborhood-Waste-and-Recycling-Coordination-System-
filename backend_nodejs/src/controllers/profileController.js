const User = require('../models/User');


// =====================================================
// GET PROFILE
// =====================================================

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select(
      '-password -otp -otpExpiresAt -resetOtp -resetOtpExpiresAt'
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.status(200).json({
      success: true,
      user,
    });

  } catch (error) {
    console.error('Get profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to retrieve profile',
    });
  }
};


// =====================================================
// UPDATE PROFILE
// =====================================================

const updateProfile = async (req, res) => {
  try {
    const {
      name,
      phone,
      bio,
      location,
      locationCoordinates,
      restaurantName,
      restaurantAddress,
      licenseNumber,
      vehicleType,
      profilePicture,
    } = req.body;

    const updateData = {};

    if (name !== undefined) updateData.name = name.trim();
    if (phone !== undefined) updateData.phone = phone.trim();
    if (bio !== undefined) updateData.bio = bio.trim();
    if (location !== undefined) updateData.location = location.trim();
    if (locationCoordinates !== undefined) updateData.locationCoordinates = locationCoordinates;
    if (profilePicture !== undefined) updateData.profilePicture = profilePicture;

    // Role-specific
    const role = req.user.role;
    if (role === 'restaurant_owner') {
      if (restaurantName !== undefined) updateData.restaurantName = restaurantName;
      if (restaurantAddress !== undefined) updateData.restaurantAddress = restaurantAddress;
    }
    if (role === 'driver') {
      if (licenseNumber !== undefined) updateData.licenseNumber = licenseNumber;
      if (vehicleType !== undefined) updateData.vehicleType = vehicleType;
    }

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password -otp -otpExpiresAt -resetOtp -resetOtpExpiresAt');

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user,
    });

  } catch (error) {
    console.error('Update profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Unable to update profile',
    });
  }
};


// =====================================================
// EXPORT
// =====================================================

module.exports = {
  getProfile,
  updateProfile,
};
