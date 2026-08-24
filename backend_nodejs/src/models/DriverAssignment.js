const mongoose = require('mongoose');

const driverAssignmentSchema = new mongoose.Schema(
  {
    requestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CollectionRequest',
      required: true,
    },

    driverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    assignedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    assignedAt: {
      type: Date,
      default: Date.now,
    },

    status: {
      type: String,
      enum: ['Assigned', 'Accepted', 'Rejected'],
      default: 'Assigned',
    },

    notes: {
      type: String,
      default: '',
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure one assignment per request (prevents duplicate assignments)
driverAssignmentSchema.index({ requestId: 1 }, { unique: true });
driverAssignmentSchema.index({ driverId: 1 });
driverAssignmentSchema.index({ status: 1 });

module.exports = mongoose.model(
  'DriverAssignment',
  driverAssignmentSchema
);
