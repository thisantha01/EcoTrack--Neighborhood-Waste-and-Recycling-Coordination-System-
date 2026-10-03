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

// Notification Trigger: Detect status transition to 'accepted' or 'scheduled'
collectionRequestSchema.pre('save', function () {
  if (this.isModified('status')) {
    if (this.status === 'scheduled') {
      this._wasJustScheduled = true;
    } else if (this.status === 'accepted') {
      this._wasJustAccepted = true;
    }
  }
});

collectionRequestSchema.post('save', async function (doc) {
  if (doc._wasJustAccepted || doc._wasJustScheduled) {
    try {
      const Notification = require('./Notification');
      const User = require('./User');
      const isScheduled = doc._wasJustScheduled || doc.status === 'scheduled';
      const notifType = isScheduled ? 'request_scheduled' : 'request_accepted';

      // Avoid duplicate notifications for the same event
      const existing = await Notification.findOne({
        relatedId: doc._id,
        type: notifType,
      });
      if (existing) return;

      const wasteType =
        (Array.isArray(doc.wasteTypes) && doc.wasteTypes.length > 0)
          ? doc.wasteTypes.map((t) => t.charAt(0).toUpperCase() + t.slice(1)).join(', ')
          : (doc.wasteType ? doc.wasteType.charAt(0).toUpperCase() + doc.wasteType.slice(1) : 'waste');
      const qty = doc.estimatedQuantity ? `${doc.estimatedQuantity} kg` : '';

      let driverName = null;
      if (doc.assignedDriver) {
        try {
          const driver = await User.findById(doc.assignedDriver).select('name');
          if (driver) driverName = driver.name;
        } catch (_) {}
      }

      const title = isScheduled
        ? 'Collection Request Scheduled! 🚚'
        : 'Collection Request Accepted! ✅';

      const message = isScheduled
        ? (driverName
            ? `Your collection request for ${wasteType} ${qty ? `(${qty})` : ''} at ${doc.location || 'your location'} has been confirmed and scheduled with driver ${driverName}.`
            : `Your collection request for ${wasteType} ${qty ? `(${qty})` : ''} at ${doc.location || 'your location'} has been confirmed and scheduled for pickup.`)
        : `Your collection request for ${wasteType} ${qty ? `(${qty})` : ''} at ${doc.location || 'your location'} has been accepted and confirmed.`;

      await Notification.create({
        recipient: doc.requester,
        title,
        message,
        type: notifType,
        relatedId: doc._id,
        metadata: {
          requestId: doc._id,
          wasteType: doc.wasteType,
          wasteTypes: doc.wasteTypes,
          estimatedQuantity: doc.estimatedQuantity,
          location: doc.location,
          preferredDate: doc.preferredDate,
          preferredTime: doc.preferredTime,
          driverName: driverName,
          status: doc.status,
          scheduledAt: isScheduled ? new Date() : undefined,
          acceptedAt: new Date(),
        },
      });
    } catch (err) {
      console.error('Error generating request notification:', err);
    }
  }
});

module.exports = mongoose.model('CollectionRequest', collectionRequestSchema);
