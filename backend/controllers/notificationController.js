const Notification = require('../models/Notification');
const {
  ensureVehicleExpiryNotifications,
  ensurePaymentNotifications,
} = require('../services/notificationService');

const getNotifications = async (req, res) => {
  if (req.user.role === 'owner' || req.user.role === 'employee') {
    await ensureVehicleExpiryNotifications({ userId: req.user._id });
    await ensurePaymentNotifications({ userId: req.user._id });
  }

  const notifications = await Notification.find({ userId: req.user._id }).sort({ createdAt: -1 });
  res.json(notifications);
};

const createNotification = async (req, res) => {
  const payload = req.body || {};
  const notification = await Notification.create({
    userId: payload.userId || req.user._id,
    assignedTo: payload.assignedTo || payload.userId || req.user._id,
    relatedEntityId: payload.relatedEntityId,
    title: payload.title,
    message: payload.message,
    type: payload.type || 'general',
    status: payload.status || 'pending',
    actionRequired: payload.actionRequired !== undefined ? Boolean(payload.actionRequired) : true,
    meta: payload.meta,
  });

  res.status(201).json(notification);
};

const updateNotification = async (req, res) => {
  const notification = await Notification.findById(req.params.id);
  if (!notification) {
    res.status(404);
    throw new Error('Notification not found');
  }

  if (String(notification.userId) !== String(req.user._id)) {
    res.status(403);
    throw new Error('Forbidden');
  }

  const { status, isRead, actionRequired, meta } = req.body || {};

  if (status) {
    notification.status = status;
    if (status === 'completed') {
      notification.completedAt = new Date();
      notification.isRead = true;
    }
  }

  if (isRead !== undefined) {
    notification.isRead = Boolean(isRead);
  }

  if (actionRequired !== undefined) {
    notification.actionRequired = Boolean(actionRequired);
  }

  if (meta !== undefined) {
    notification.meta = meta;
  }

  await notification.save();
  res.json(notification);
};

const markNotificationRead = async (req, res) => {
  const notification = await Notification.findById(req.params.id);
  if (!notification) {
    res.status(404);
    throw new Error('Notification not found');
  }

  if (String(notification.userId) !== String(req.user._id)) {
    res.status(403);
    throw new Error('Forbidden');
  }

  notification.isRead = true;
  await notification.save();

  res.json(notification);
};

module.exports = { getNotifications, createNotification, updateNotification, markNotificationRead };
