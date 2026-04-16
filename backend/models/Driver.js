const mongoose = require('mongoose');

const leaveSchema = new mongoose.Schema(
  {
    from: { type: Date, required: true },
    to: { type: Date, required: true },
    reason: { type: String, required: true },
    status: { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

const driverSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    phone: { type: String, required: true },
    licenseNumber: { type: String, required: true, unique: true },
    salaryPerDay: { type: Number, default: 0 },
    salaryPerTrip: { type: Number, default: 0 },
    bataRate: { type: Number, default: 0 },
    totalWorkingHours: { type: Number, default: 0 },
    totalWorkingDays: { type: Number, default: 0 },
    totalTripsCompleted: { type: Number, default: 0 },
    totalBataEarned: { type: Number, default: 0 },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true, sparse: true },
    leaves: [leaveSchema],
  },
  { timestamps: true }
);

driverSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Driver', driverSchema);
