const mongoose = require('mongoose');

const billSchema = new mongoose.Schema(
  {
    tripId: { type: mongoose.Schema.Types.ObjectId, ref: 'Trip' },
    billDate: { type: Date, default: Date.now },
    tripDate: { type: Date, default: Date.now },
    vehicleNumber: { type: String, default: 'N/A' },
    tripDetails: { type: String, default: 'Business trip' },
    startTime: { type: Date },
    endTime: { type: Date },
    startKm: { type: Number, default: 0, min: 0 },
    endKm: { type: Number, default: 0, min: 0 },
    ratePerKm: { type: Number, default: 0, min: 0 },
    dayRent: { type: Number, default: 0 },
    hourRent: { type: Number, default: 0 },
    numberOfDays: { type: Number, default: 0 },
    numberOfHours: { type: Number, default: 0 },
    driverBata: { type: Number, default: 0 },
    tollCharges: { type: Number, default: 0 },
    fastagCharges: { type: Number, default: 0 },
    permitCharges: { type: Number, default: 0 },
    parkingCharges: { type: Number, default: 0 },
    advanceReceived: { type: Number, default: 0 },
    totalKm: { type: Number, default: 0 },
    kmCharge: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
    payableAmount: { type: Number, default: 0 },
    pdfPath: { type: String },
    paymentStatus: { type: String, enum: ['pending', 'partial', 'paid'], default: 'pending' },
  },
  { timestamps: true }
);

billSchema.index({ tripId: 1 }, { unique: true, sparse: true });
billSchema.index({ paymentStatus: 1, createdAt: -1 });

module.exports = mongoose.model('Bill', billSchema);
