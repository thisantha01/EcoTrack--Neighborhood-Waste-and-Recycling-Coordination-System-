const mongoose = require('mongoose');

const routeStopSchema = new mongoose.Schema(
  {
    collectionRequestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CollectionRequest',
      required: false,
      default: null,
    },
    location: {
      lat: {
        type: Number,
      },
      lng: {
        type: Number,
      },
    },
    address: {
      type: String,
      trim: true,
    },
    sequenceOrder: {
      type: Number,
    },
    status: {
      type: String,
      enum: ['pending', 'collected', 'skipped'],
      default: 'pending',
    },
  },
  { _id: false }
);

const routeSchema = new mongoose.Schema(
  {
    routeName: {
      type: String,
      required: true,
      trim: true,
    },
    zone: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    assignedLocations: {
      type: [String],
      default: [],
    },
    areaCoordinates: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },
    operatingDays: {
      type: [String],
      enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      default: [],
    },
    targetWasteType: {
      type: String,
      enum: [
        'weekly_schedule',
        'organic',
        'plastic_paper',
        'glass_others',
        'special_requests',
        'all',
        // Backward compatibility
        'plastic',
        'paper',
        'glass_metal',
        'other',
      ],
      default: 'weekly_schedule',
    },
    weeklyCategorySchedule: [
      {
        day: {
          type: String,
          enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
        },
        category: {
          type: String,
          default: 'organic',
        },
      },
    ],
    date: { type: Date, default: null },
    assignedDriver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    routeStops: {
      type: [routeStopSchema],
      default: [],
    },
    // Kept for older documents and clients. New writes use routeStops.
    stops: {
      type: [routeStopSchema],
      default: [],
    },
    status: {
      type: String,
      enum: ['draft', 'assigned', 'in-progress', 'completed', 'Active', 'Inactive'],
      default: 'Active',
    },
    routeStatus: {
      type: String,
      enum: ['Active', 'Inactive'],
      default: 'Active',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Route', routeSchema);
