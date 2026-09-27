const mongoose = require('mongoose');

const wasteWeighInSchema = new mongoose.Schema({
  driver: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  route: { type: mongoose.Schema.Types.ObjectId, ref: 'Route', default: null },
  recordedAt: { type: Date, default: Date.now },
  weightsKg: {
    organic: { type: Number, min: 0, default: 0 },
    plasticPaper: { type: Number, min: 0, default: 0 },
    glassOthers: { type: Number, min: 0, default: 0 },
  },
  notes: { type: String, trim: true, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('WasteWeighIn', wasteWeighInSchema);
