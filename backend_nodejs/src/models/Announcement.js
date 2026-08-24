const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema(
  {
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    content: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ['announcement', 'group_collection', 'pickup_schedule', 'activity'],
      default: 'announcement',
    },
    scheduledAt: {
      type: Date,
      default: null,
    },
    location: {
      type: String,
      default: '',
    },
    targetRoles: [
      {
        type: String,
        enum: ['neighbour', 'restaurant_owner', 'driver', 'recycling_manager', 'all'],
      },
    ],
    views: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Announcement', announcementSchema);
