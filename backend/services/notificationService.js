const Notification = require('../models/Notification');
const User = require('../models/User');
const Vehicle = require('../models/Vehicle');
const Bill = require('../models/Bill');

const getOwnerUser = async () => {
  return User.findOne({ role: 'owner' }).select('_id name email');
};

const createNotification = async ({
  userId,
  assignedTo,
  type,
  title,
  message,
  relatedEntityId,
  meta,
  actionRequired = true,
}) => {
  return Notification.create({
    userId,
    assignedTo: assignedTo || userId,
    type,
    title,
    message,
    relatedEntityId,
    meta,
    actionRequired,
    status: 'pending',
    isRead: false,
  });
};

const findOrCreatePendingNotification = async ({
  userId,
  assignedTo,
  type,
  relatedEntityId,
  title,
  message,
  meta,
  actionRequired = true,
}) => {
  const existing = await Notification.findOne({
    userId,
    type,
    relatedEntityId,
    status: 'pending',
  });
  if (existing) {
    existing.title = title;
    existing.message = message;
    existing.meta = meta;
    existing.actionRequired = actionRequired;
    await existing.save();
    return existing;
  }

  return createNotification({
    userId,
    assignedTo,
    type,
    title,
    message,
    relatedEntityId,
    meta,
    actionRequired,
  });
};

const completeNotificationByEntity = async ({ type, relatedEntityId }) => {
  const notification = await Notification.findOne({
    type,
    relatedEntityId,
    status: 'pending',
  });
  if (!notification) {
    return null;
  }
  notification.status = 'completed';
  notification.completedAt = new Date();
  notification.isRead = true;
  await notification.save();
  return notification;
};

const completeNotificationsByFilter = async (filter) => {
  await Notification.updateMany(
    { ...filter, status: 'pending' },
    { $set: { status: 'completed', completedAt: new Date(), isRead: true } }
  );
};

const expiryTypes = [
  { key: 'insuranceDate', type: 'vehicle_insurance', label: 'Insurance' },
  { key: 'fcDate', type: 'vehicle_fc', label: 'FC' },
  { key: 'permitDate', type: 'vehicle_permit', label: 'Permit' },
  { key: 'pucDate', type: 'vehicle_puc', label: 'PUC' },
];

const ensureVehicleExpiryNotifications = async ({ userId, daysAhead = 30 }) => {
  const now = new Date();
  const threshold = new Date();
  threshold.setDate(threshold.getDate() + daysAhead);

  const vehicles = await Vehicle.find();
  for (const vehicle of vehicles) {
    for (const item of expiryTypes) {
      const expiryDate = vehicle[item.key];
      if (!expiryDate) {
        continue;
      }

      const state = expiryDate < now ? 'expired' : expiryDate <= threshold ? 'upcoming' : null;
      const type = item.type;
      if (!state) {
        await completeNotificationsByFilter({
          userId,
          type,
          relatedEntityId: vehicle._id,
        });
        continue;
      }

      await findOrCreatePendingNotification({
        userId,
        assignedTo: userId,
        type,
        relatedEntityId: vehicle._id,
        title: `${item.label} ${state === 'expired' ? 'Expired' : 'Expiry Upcoming'}`,
        message: `Vehicle ${vehicle.number} ${item.label} ${state === 'expired' ? 'expired' : 'expires soon'} on ${new Date(expiryDate).toDateString()}.`,
        meta: {
          vehicleNumber: vehicle.number,
          expiryType: item.label,
          expiryDate,
          state,
        },
        actionRequired: true,
      });
    }
  }
};

const ensurePaymentNotifications = async ({ userId, overdueDays = 7 }) => {
  const now = new Date();
  const overdueThreshold = new Date();
  overdueThreshold.setDate(overdueThreshold.getDate() - overdueDays);

  const bills = await Bill.find({ paymentStatus: { $in: ['pending', 'partial'] } });
  for (const bill of bills) {
    const isOverdue = bill.billDate && new Date(bill.billDate) < overdueThreshold;
    const type = isOverdue ? 'payment_overdue' : 'payment_pending';
    const title = isOverdue ? 'Invoice Payment Overdue' : 'Payment Pending';
    const message = isOverdue
      ? `Invoice ${bill.billCode} is overdue. Remaining amount: ${Number(bill.remainingAmount || 0).toFixed(2)}.`
      : `Payment pending for invoice ${bill.billCode}. Remaining amount: ${Number(bill.remainingAmount || 0).toFixed(2)}.`;

    await findOrCreatePendingNotification({
      userId,
      assignedTo: userId,
      type,
      relatedEntityId: bill._id,
      title,
      message,
      meta: {
        billId: bill._id,
        billCode: bill.billCode,
        remainingAmount: bill.remainingAmount,
        isOverdue,
      },
      actionRequired: true,
    });
  }
};

module.exports = {
  getOwnerUser,
  createNotification,
  findOrCreatePendingNotification,
  completeNotificationByEntity,
  completeNotificationsByFilter,
  ensureVehicleExpiryNotifications,
  ensurePaymentNotifications,
};
