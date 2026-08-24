const mongoose = require('mongoose');

const badgeSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, default: '' },
  icon: { type: String, default: '🏆' },
  earnedAt: { type: Date, default: Date.now },
});

const userPointsSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    points: {
      type: Number,
      default: 0,
    },
    level: {
      type: String,
      enum: ['bronze', 'silver', 'gold', 'platinum'],
      default: 'bronze',
    },
    badges: [badgeSchema],
    eventsJoined: {
      type: Number,
      default: 0,
    },
    postsCreated: {
      type: Number,
      default: 0,
    },
    reportsSubmitted: {
      type: Number,
      default: 0,
    },
    totalWasteCollected: {
      type: Number, // kg
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserPoints', userPointsSchema);
