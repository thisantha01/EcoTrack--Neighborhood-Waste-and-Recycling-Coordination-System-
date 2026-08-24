const mongoose = require('mongoose');

const cleanupEventSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
      default: '',
    },
    location: {
      type: String,
      required: true,
      trim: true,
    },
    coordinates: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },
    scheduledAt: {
      type: Date,
      required: true,
    },
    organizer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    participants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    maxParticipants: {
      type: Number,
      default: 50,
    },
    status: {
      type: String,
      enum: ['upcoming', 'ongoing', 'completed', 'cancelled'],
      default: 'upcoming',
    },
    wasteCollected: {
      type: Number, // kg
      default: 0,
    },
    wasteRecycled: {
      type: Number, // kg
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('CleanupEvent', cleanupEventSchema);
