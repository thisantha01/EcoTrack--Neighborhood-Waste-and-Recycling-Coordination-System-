const mongoose = require('mongoose');

const statusHistorySchema = new mongoose.Schema({
  status: {
    type: String,
    enum: ['requested', 'accepted', 'scheduled', 'collected', 'cancelled'],
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

const collectionRequestSchema = new mongoose.Schema({
  requester: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  wasteType: {
    type: String,
    enum: ['organic', 'plastic', 'paper', 'glass', 'metal', 'electronic', 'hazardous', 'other'],
    required: [true, 'Waste type is required']
  },
  estimatedQuantity: {
    type: Number,
    required: [true, 'Estimated quantity is required'],
    min: 0
  },
  description: {
    type: String,
    default: ''
  },
  imageUrl: {
    type: String,
    default: null
  },
  location: {
    type: String,
    required: [true, 'Pickup location is required']
  },
  coordinates: {
    lat: { type: Number },
    lng: { type: Number }
  },
  preferredDate: {
    type: Date
  },
  preferredTime: {
    type: String
  },
  status: {
    type: String,
    enum: ['requested', 'accepted', 'scheduled', 'collected', 'cancelled'],
    default: 'requested'
  },
  statusHistory: [statusHistorySchema],
  assignedDriver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  }
}, {
  timestamps: true
});

collectionRequestSchema.index({ requester: 1, createdAt: -1 });
collectionRequestSchema.index({ status: 1 });
collectionRequestSchema.index({ assignedDriver: 1 });

module.exports = mongoose.model('CollectionRequest', collectionRequestSchema);
