const mongoose = require('mongoose');

const billSequenceSchema = new mongoose.Schema(
  {
    year: { type: Number, required: true, unique: true },
    seq: { type: Number, required: true, default: 0 },
  },
  { timestamps: true }
);

billSequenceSchema.index({ year: 1 }, { unique: true });

module.exports = mongoose.model('BillSequence', billSequenceSchema);
