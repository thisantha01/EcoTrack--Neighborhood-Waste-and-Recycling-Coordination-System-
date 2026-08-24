const mongoose = require('mongoose');

const pickupSchema = new mongoose.Schema(
  {
    pickupNumber: { type: String, required: true, unique: true },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    customerName: { type: String, required: true },
    customerPhone: { type: String },
    address: { type: String, required: true },
    wasteType: { type: String, required: true },
    weightKg: { type: Number, required: true, default: 0 },
    scheduledTime: { type: String, required: true },
    status: {
      type: String,
      enum: ['scheduled', 'accepted', 'completed', 'cancelled'],
      default: 'scheduled',
    },
    notes: { type: String },
    completedAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Pickup', pickupSchema);