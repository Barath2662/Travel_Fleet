const mongoose = require('mongoose');

const fastagRequestSchema = new mongoose.Schema(
  {
    tripId: { type: mongoose.Schema.Types.ObjectId, ref: 'Trip', required: true },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'Driver', required: true },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    applicable: { type: Boolean, default: true },
    amount: { type: Number, default: 0, min: 0 },
    status: { type: String, enum: ['pending', 'completed'], default: 'pending' },
  },
  { timestamps: true }
);

fastagRequestSchema.index({ tripId: 1 }, { unique: true });
fastagRequestSchema.index({ ownerId: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('FastagRequest', fastagRequestSchema);
