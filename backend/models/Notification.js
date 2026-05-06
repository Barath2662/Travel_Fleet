const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    relatedEntityId: { type: mongoose.Schema.Types.ObjectId },
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: { type: String, default: 'general' },
    status: { type: String, enum: ['pending', 'completed'], default: 'pending' },
    actionRequired: { type: Boolean, default: true },
    isRead: { type: Boolean, default: false },
    completedAt: { type: Date },
    meta: { type: Object },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);
