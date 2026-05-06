const FastagRequest = require('../models/FastagRequest');
const Trip = require('../models/Trip');
const Bill = require('../models/Bill');
const { computeBillFields, toNumber } = require('../services/billingService');
const {
  getOwnerUser,
  findOrCreatePendingNotification,
  completeNotificationByEntity,
} = require('../services/notificationService');

const requestFastag = async (req, res) => {
  const { tripId, applicable = true } = req.body;
  const trip = await Trip.findById(tripId)
    .populate('driverId', 'name')
    .populate('vehicleId', 'number');
  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (!applicable) {
    return res.status(400).json({ message: 'Fastag not applicable' });
  }

  const owner = await getOwnerUser();
  if (!owner) {
    res.status(400);
    throw new Error('Owner account missing');
  }

  const existing = await FastagRequest.findOne({ tripId: trip._id });
  if (existing) {
    return res.json(existing);
  }

  const request = await FastagRequest.create({
    tripId: trip._id,
    driverId: trip.driverId,
    ownerId: owner._id,
    applicable: true,
  });

  await findOrCreatePendingNotification({
    userId: owner._id,
    assignedTo: owner._id,
    type: 'fastag_request',
    relatedEntityId: request._id,
    title: 'FASTag Amount Pending',
    message: `Fastag amount pending for Trip #${trip._id}.`,
    meta: {
      tripId: trip._id,
      driverName: trip.driverId?.name,
      vehicleNumber: trip.vehicleId?.number,
    },
    actionRequired: true,
  });

  res.status(201).json(request);
};

const setFastagAmount = async (req, res) => {
  const { requestId, tripId, amount } = req.body;
  const numericAmount = toNumber(amount);
  if (!Number.isFinite(numericAmount) || numericAmount < 0) {
    res.status(400);
    throw new Error('FASTag amount must be 0 or greater');
  }

  const request = requestId
    ? await FastagRequest.findById(requestId)
    : await FastagRequest.findOne({ tripId });

  if (!request) {
    res.status(404);
    throw new Error('FASTag request not found');
  }

  const trip = await Trip.findById(request.tripId);
  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  request.amount = numericAmount;
  request.status = 'completed';
  await request.save();

  trip.fastagApplicable = true;
  trip.fastagAmount = numericAmount;
  await trip.save();

  const bill = await Bill.findOne({ tripId: trip._id });
  if (bill) {
    bill.fastagCharges = numericAmount;
    const totals = computeBillFields(bill);
    bill.totalAmount = totals.totalAmount;
    bill.gstAmount = totals.gstAmount;
    bill.finalAmount = totals.finalAmount;
    bill.payableAmount = totals.payableAmount;
    bill.remainingAmount = Math.max(totals.payableAmount - toNumber(bill.paidAmount), 0);
    bill.paymentStatus = bill.remainingAmount > 0 ? 'pending' : 'paid';
    await bill.save();
  }

  await completeNotificationByEntity({
    type: 'fastag_request',
    relatedEntityId: request._id,
  });

  res.json({ request, trip });
};

module.exports = { requestFastag, setFastagAmount };
