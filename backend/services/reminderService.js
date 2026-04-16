const cron = require('node-cron');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendPushNotification } = require('./fcmService');

const createOwnerNotifications = async (title, message, type, meta) => {
  const owners = await User.find({ role: 'owner' });

  await Promise.all(
    owners.map(async (owner) => {
      await Notification.create({
        userId: owner._id,
        title,
        message,
        type,
        meta,
      });

      await sendPushNotification({
        token: owner.fcmToken,
        title,
        body: message,
      });
    })
  );
};

const checkVehicleAlerts = async () => {
  const expiryDays = Number(process.env.EXPIRY_ALERT_DAYS || 15);
  const serviceBufferKm = Number(process.env.SERVICE_ALERT_KM_BUFFER || 500);

  const now = new Date();
  const threshold = new Date(now);
  threshold.setDate(threshold.getDate() + expiryDays);

  const expiringVehicles = await Vehicle.find({
    $or: [
      { fcDate: { $lte: threshold } },
      { insuranceDate: { $lte: threshold } },
      { pucDate: { $lte: threshold } },
      { permitDate: { $lte: threshold } },
    ],
  });

  await Promise.all(
    expiringVehicles.map((vehicle) =>
      createOwnerNotifications(
        'Vehicle Expiry Alert',
        `Vehicle ${vehicle.number} has a document expiry approaching.`,
        'expiry',
        { vehicleId: String(vehicle._id) }
      )
    )
  );

  const serviceVehicles = await Vehicle.find({
    $expr: {
      $lte: [{ $subtract: ['$nextServiceKm', '$currentKm'] }, serviceBufferKm],
    },
  });

  await Promise.all(
    serviceVehicles.map((vehicle) =>
      createOwnerNotifications(
        'Service Reminder',
        `Vehicle ${vehicle.number} is nearing service KM (${vehicle.nextServiceKm}).`,
        'service',
        { vehicleId: String(vehicle._id) }
      )
    )
  );
};

const startSchedulers = () => {
  cron.schedule('0 8 * * *', async () => {
    try {
      await checkVehicleAlerts();
    } catch (error) {
      console.error('Scheduler error:', error.message);
    }
  });
};

module.exports = { startSchedulers, checkVehicleAlerts };
