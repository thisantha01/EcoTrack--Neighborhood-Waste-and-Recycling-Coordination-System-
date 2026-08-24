const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
  routeName: { type: String, required: true },
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  scheduledDate: { type: Date, required: true },
  status: { type: String, enum: ['Scheduled', 'In-Progress', 'Completed'], default: 'Scheduled' },
  pickupRequests: [{ type: mongoose.Schema.Types.ObjectId, ref: 'CollectionRequest' }]
}, { timestamps: true });

module.exports = mongoose.model('Route', routeSchema);