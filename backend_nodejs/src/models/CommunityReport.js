const mongoose = require('mongoose');

const reportStatusHistorySchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ['open', 'in_progress', 'resolved'],
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  note: {
    type: String,
    default: ''
  }
}, { _id: false });

const additionalInfoSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    text: {
      type: String,
      trim: true,
      default: '',
    },
    imageUrl: {
      type: String,
      default: null,
    },
  },
  { timestamps: true }
);

const communityReportSchema = new mongoose.Schema(
  {
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
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
    imageUrl: {
      type: String,
      default: null,
    },
    type: {
      type: String,
      enum: ['illegal_dumping', 'overflow', 'contamination', 'other'],
      default: 'illegal_dumping',
    },
    status: {
      type: String,
      enum: ['open', 'in_progress', 'resolved'],
      default: 'open',
    },
    upvotes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    additionalInfo: [additionalInfoSchema],
    statusHistory: [reportStatusHistorySchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model('CommunityReport', communityReportSchema);
