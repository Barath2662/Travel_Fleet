const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    billId: { type: mongoose.Schema.Types.ObjectId, ref: 'Bill', required: true },
    amount: { type: Number, required: true, min: 0 },
    paymentAmount: { type: Number, default: 0, min: 0 },
    status: { type: String, enum: ['paid', 'pending'], default: 'pending' },
    paidAt: { type: Date },
    paymentDate: { type: Date },
    paymentMethod: { type: String },
    remainingBalance: { type: Number, default: 0, min: 0 },
    notes: { type: String },
    idempotencyKey: { type: String },
    updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    editHistory: [
      {
        amount: { type: Number, min: 0 },
        paymentDate: { type: Date },
        paymentMethod: { type: String },
        notes: { type: String },
        updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        updatedAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

paymentSchema.index({ billId: 1, createdAt: -1 });
paymentSchema.index({ idempotencyKey: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('Payment', paymentSchema);
