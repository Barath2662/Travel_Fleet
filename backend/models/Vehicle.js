const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema(
  {
    number: { type: String, required: true, unique: true, uppercase: true, trim: true },
    category: {
      type: String,
      required: true,
      enum: ['sedan', 'suv', 'mvp', 'van', 'hatchback', 'luxury', 'mini_bus', 'other'],
      default: 'sedan',
    },
    seats: { type: Number, required: true, min: 1, default: 4 },
    fcDate: { type: Date, required: true },
    insuranceDate: { type: Date, required: true },
    pucDate: { type: Date, required: true },
    permitDate: { type: Date, required: true },
    nextServiceKm: { type: Number, required: true, min: 0 },
    currentKm: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Vehicle', vehicleSchema);
