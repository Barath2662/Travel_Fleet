const mongoose = require('mongoose');

const advanceSchema = new mongoose.Schema(
  {
    amount: { type: Number, required: true, min: 0 },
    addedByRole: { type: String, enum: ['owner', 'employee', 'driver'], required: true },
    addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true }
);

const routePointSchema = new mongoose.Schema(
  {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    capturedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const tripSchema = new mongoose.Schema(
  {
    pickupDateTime: { type: Date, required: true },
    customerName: { type: String, required: true, trim: true },
    customerMobile: { type: String, required: true, trim: true },
    pickupLocation: { type: String, required: true },
    placesToVisit: [{ type: String, required: true }],
    numberOfDays: { type: Number, required: true, min: 1 },
    driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'Driver', required: true },
    vehicleId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vehicle', required: true },
    startTime: { type: Date },
    endTime: { type: Date },
    startKm: { type: Number, min: 0 },
    endKm: { type: Number, min: 0 },
    tollApplicable: { type: Boolean, default: false },
    permitApplicable: { type: Boolean, default: false },
    parkingApplicable: { type: Boolean, default: false },
    fastagApplicable: { type: Boolean, default: false },
    tollAmount: { type: Number, default: 0, min: 0 },
    permitAmount: { type: Number, default: 0, min: 0 },
    parkingAmount: { type: Number, default: 0, min: 0 },
    fastagAmount: { type: Number, default: 0, min: 0 },
    tripNotes: { type: String, trim: true },
    routePoints: [routePointSchema],
    driverBataAssigned: { type: Number, default: 0, min: 0 },
    driverBataAssignedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    driverBataAssignedAt: { type: Date },
    driverBataCredited: { type: Boolean, default: false },
    status: {
      type: String,
      enum: ['scheduled', 'in_progress', 'completed'],
      default: 'scheduled',
    },
    advances: [advanceSchema],
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Trip', tripSchema);
