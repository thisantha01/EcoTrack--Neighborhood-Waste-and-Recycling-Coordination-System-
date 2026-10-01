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
    default: 'other',
  },
  wasteTypes: {
    type: [String],
    enum: ['organic', 'plastic', 'paper', 'glass', 'metal', 'electronic', 'hazardous', 'other'],
    default: [],
    validate: {
      validator: function(v) {
        return v.length > 0;
      },
      message: 'At least one waste type is required',
    },
  },
  estimatedQuantity: {
    type: Number,
    required: [true, 'Estimated quantity is required'],
    min: 0
  },
  collectedQuantity: {
    type: Number,
    min: 0,
    default: null,
  },
  driverNotes: {
    type: String,
    default: '',
    trim: true,
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
  },
  suggestedRoute: {
    route: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Route',
      default: null
    },
    distanceKm: {
      type: Number,
      default: null
    },
    reason: {
      type: String,
      default: ''
    },
    suggestedAt: {
      type: Date,
      default: null
    }
  }
}, {
  timestamps: true
});

collectionRequestSchema.index({ requester: 1, createdAt: -1 });
collectionRequestSchema.index({ createdAt: -1 });
collectionRequestSchema.index({ status: 1 });
collectionRequestSchema.index({ assignedDriver: 1 });

// Notification Trigger: Detect status transition to 'accepted'
collectionRequestSchema.pre('save', function (next) {
  if (this.isModified('status') && this.status === 'accepted') {
    this._wasJustAccepted = true;
  }
  next();
});

collectionRequestSchema.post('save', async function (doc) {
  if (doc._wasJustAccepted) {
    try {
      const Notification = require('./Notification');
      const wasteType =
        doc.wasteType ||
        (Array.isArray(doc.wasteTypes) && doc.wasteTypes.length > 0
          ? doc.wasteTypes.join(', ')
          : 'waste');
      const qty = doc.estimatedQuantity ? `${doc.estimatedQuantity} kg` : '';

      await Notification.create({
        recipient: doc.requester,
        title: 'Collection Request Accepted! ✅',
        message: `Your collection request for ${wasteType} ${qty ? `(${qty})` : ''} at ${doc.location || 'your location'} has been accepted and confirmed.`,
        type: 'request_accepted',
        relatedId: doc._id,
        metadata: {
          requestId: doc._id,
          wasteType: doc.wasteType,
          wasteTypes: doc.wasteTypes,
          estimatedQuantity: doc.estimatedQuantity,
          location: doc.location,
          preferredDate: doc.preferredDate,
          preferredTime: doc.preferredTime,
          status: 'accepted',
          acceptedAt: new Date(),
        },
      });
    } catch (err) {
      console.error('Error generating request acceptance notification:', err);
    }
  }
});

module.exports = mongoose.model('CollectionRequest', collectionRequestSchema);
