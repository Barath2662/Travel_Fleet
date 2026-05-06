const { body } = require('express-validator');
const mongoose = require('mongoose');
const path = require('path');
const Bill = require('../models/Bill');
const BillSequence = require('../models/BillSequence');
const Trip = require('../models/Trip');
const Payment = require('../models/Payment');
const { generateInvoicePdf } = require('../services/pdfService');
const { formatBillCode, syncBillFromPayments } = require('../services/billConsistencyService');
const { computeBillFields, toNumber } = require('../services/billingService');

const billValidation = [
  body('tripId').optional({ checkFalsy: true }).isMongoId(),
  body('billDate').optional({ checkFalsy: true }).isISO8601(),
  body('tripDate').optional({ checkFalsy: true }).isISO8601(),
  body('startKm').optional({ checkFalsy: true }).isNumeric(),
  body('endKm').optional({ checkFalsy: true }).isNumeric(),
  body('totalKm').optional({ checkFalsy: true }).isNumeric(),
  body('ratePerKm').optional({ checkFalsy: true }).isNumeric(),
  body('dayRent').optional({ checkFalsy: true }).isNumeric(),
  body('hourRent').optional({ checkFalsy: true }).isNumeric(),
  body('numberOfDays').optional({ checkFalsy: true }).isNumeric(),
  body('numberOfHours').optional({ checkFalsy: true }).isNumeric(),
  body('totalDays').optional({ checkFalsy: true }).isNumeric(),
  body('totalHours').optional({ checkFalsy: true }).isNumeric(),
  body('baseFare').optional({ checkFalsy: true }).isNumeric(),
  body('driverBata').optional({ checkFalsy: true }).isNumeric(),
  body('tollCharges').optional({ checkFalsy: true }).isNumeric(),
  body('fastagCharges').optional({ checkFalsy: true }).isNumeric(),
  body('permitCharges').optional({ checkFalsy: true }).isNumeric(),
  body('waitingCharges').optional({ checkFalsy: true }).isNumeric(),
  body('extraCharges').optional({ checkFalsy: true }).isNumeric(),
  body('parkingCharges').optional({ checkFalsy: true }).isNumeric(),
  body('advanceReceived').optional({ checkFalsy: true }).isNumeric(),
  body('gstPercent').optional({ checkFalsy: true }).isNumeric(),
];

const sumTripAdvances = (trip) => {
  if (!trip || !Array.isArray(trip.advances)) return 0;
  return trip.advances.reduce((total, item) => total + toNumber(item.amount), 0);
};

const createBill = async (req, res) => {
  const payload = req.body;
  const billId = new mongoose.Types.ObjectId();

  const trip = payload.tripId
    ? await Trip.findById(payload.tripId)
        .populate('vehicleId', 'number')
        .populate('driverId', 'name')
    : null;

  if (payload.tripId && !trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (trip && !['completed', 'approved'].includes(trip.status)) {
    res.status(400);
    throw new Error('Bill can only be generated for completed or approved trips');
  }

  if (trip && (await Bill.findOne({ tripId: trip._id }))) {
    res.status(409);
    throw new Error('Invoice already exists for this trip');
  }

  const billDateForSequence = payload.billDate ? new Date(payload.billDate) : new Date();
  const billYear = billDateForSequence.getFullYear();
  const sequenceDoc = await BillSequence.findOneAndUpdate(
    { year: billYear },
    { $inc: { seq: 1 } },
    { new: true, upsert: true }
  );

  const tripAdvanceTotal = sumTripAdvances(trip);
  const advanceReceived = payload.advanceReceived !== undefined
    ? Math.max(toNumber(payload.advanceReceived), 0)
    : Math.max(tripAdvanceTotal, 0);

  const baseFare = payload.baseFare !== undefined
    ? Math.max(toNumber(payload.baseFare), 0)
    : Math.max(toNumber(payload.dayRent), 0) + Math.max(toNumber(payload.hourRent), 0);
  const extraCharges = payload.extraCharges !== undefined
    ? Math.max(toNumber(payload.extraCharges), 0)
    : Math.max(toNumber(payload.parkingCharges), 0);

  const sanitizedPayload = {
    _id: billId,
    ...(payload.tripId ? { tripId: payload.tripId } : {}),
    billCode: formatBillCode(billYear, sequenceDoc.seq),
    billYear,
    billSequence: sequenceDoc.seq,
    customerName: payload.customerName || trip?.customerName || 'N/A',
    billDate: payload.billDate || new Date(),
    tripDate: payload.tripDate || payload.billDate || trip?.pickupDateTime || new Date(),
    vehicleNumber: payload.vehicleNumber || trip?.vehicleId?.number || 'N/A',
    driverName: payload.driverName || trip?.driverId?.name,
    tripDetails: payload.tripDetails || 'Business trip',
    pickupLocation: payload.pickupLocation || trip?.pickupLocation,
    dropLocation: payload.dropLocation || (Array.isArray(trip?.placesToVisit) && trip.placesToVisit.length
      ? trip.placesToVisit[trip.placesToVisit.length - 1]
      : undefined),
    tripStatus: payload.tripStatus || trip?.status,
    startTime: payload.startTime || trip?.startTime,
    endTime: payload.endTime || trip?.endTime,
    startKm: Math.max(toNumber(payload.startKm, toNumber(trip?.startKm, 0)), 0),
    endKm: Math.max(toNumber(payload.endKm, toNumber(trip?.endKm, 0)), 0),
    totalKm: Math.max(toNumber(payload.totalKm), 0),
    ratePerKm: Math.max(toNumber(payload.ratePerKm), 0),
    dayRent: Math.max(toNumber(payload.dayRent), 0),
    hourRent: Math.max(toNumber(payload.hourRent), 0),
    baseFare,
    numberOfDays: Math.max(toNumber(payload.numberOfDays), 0),
    numberOfHours: Math.max(toNumber(payload.numberOfHours), 0),
    totalDays: Math.max(toNumber(payload.totalDays), 0),
    totalHours: Math.max(toNumber(payload.totalHours), 0),
    driverBata: Math.max(toNumber(payload.driverBata, toNumber(trip?.driverBataAssigned)), 0),
    tollCharges: Math.max(toNumber(payload.tollCharges, toNumber(trip?.tollAmount)), 0),
    fastagCharges: Math.max(toNumber(payload.fastagCharges, toNumber(trip?.fastagAmount)), 0),
    permitCharges: Math.max(toNumber(payload.permitCharges, toNumber(trip?.permitCharges ?? trip?.permitAmount)), 0),
    waitingCharges: Math.max(toNumber(payload.waitingCharges), 0),
    extraCharges: Math.max(toNumber(payload.extraCharges, toNumber(trip?.extraCharges)), 0),
    parkingCharges: Math.max(toNumber(payload.parkingCharges, toNumber(trip?.parkingCharges ?? trip?.parkingAmount)), 0),
    advanceReceived,
    gstPercent: Math.max(toNumber(payload.gstPercent), 0),
  };

  if (sanitizedPayload.endKm < sanitizedPayload.startKm) {
    res.status(400);
    throw new Error('End KM cannot be less than start KM for billing');
  }

  const totals = computeBillFields(sanitizedPayload);

  const bill = await Bill.create({
    ...sanitizedPayload,
    distance: totals.distance,
    totalKm: totals.totalKm,
    kmCharge: totals.kmCharge,
    totalDays: totals.totalDays,
    totalHours: totals.totalHours,
    dayCharge: totals.dayCharge,
    hourCharge: totals.hourCharge,
    totalAmount: totals.totalAmount,
    gstAmount: totals.gstAmount,
    finalAmount: totals.finalAmount,
    payableAmount: totals.payableAmount,
    paidAmount: 0,
    remainingAmount: totals.payableAmount,
    balanceAmount: totals.payableAmount,
    paymentStatus: totals.payableAmount > 0 ? 'pending' : 'paid',
  });

  const pdf = await generateInvoicePdf(bill);
  bill.pdfPath = pdf.relativePath;
  await bill.save();

  res.status(201).json(bill);
};

const getBills = async (req, res) => {
  const query = {};

  if (req.query.status && ['pending', 'partial', 'paid'].includes(req.query.status)) {
    query.paymentStatus = req.query.status;
  }

  if (req.query.fromDate || req.query.toDate) {
    query.billDate = {};
    if (req.query.fromDate) {
      query.billDate.$gte = new Date(req.query.fromDate);
    }
    if (req.query.toDate) {
      query.billDate.$lte = new Date(req.query.toDate);
    }
  }

  const bills = await Bill.find(query)
    .populate({
      path: 'tripId',
      populate: [
        { path: 'driverId', select: 'name' },
        { path: 'vehicleId', select: 'number' },
      ],
    })
    .sort({ createdAt: -1 });

  const search = String(req.query.q || '').trim().toLowerCase();
  const filteredBills = search
    ? bills.filter((bill) => {
        const trip = bill.tripId || {};
        const driver = trip.driverId || {};
        const vehicle = trip.vehicleId || {};
        const haystack = [
          bill.billCode,
          bill.customerName,
          bill.vehicleNumber,
          bill.paymentStatus,
          String(bill._id),
          trip._id ? String(trip._id) : '',
          trip.customerName,
          trip.pickupLocation,
          driver.name,
          vehicle.number,
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase();
        return haystack.includes(search);
      })
    : bills;

  const billIds = filteredBills.map((bill) => bill._id);

  const payments = billIds.length
    ? await Payment.find({ billId: { $in: billIds } }).sort({ createdAt: -1 })
    : [];

  const paymentsByBill = new Map();
  for (const payment of payments) {
    const key = String(payment.billId);
    const list = paymentsByBill.get(key) || [];
    list.push(payment);
    paymentsByBill.set(key, list);
  }

  const hydratedBills = [];
  for (const bill of filteredBills) {
    const billPayments = paymentsByBill.get(String(bill._id)) || [];
    const synced = await syncBillFromPayments({ bill, payments: billPayments });
    const plain = synced.toObject();
    plain.payments = billPayments;
    hydratedBills.push(plain);
  }

  res.json(hydratedBills);
};

const checkBillByTripId = async (req, res) => {
  const tripId = req.params.tripId;
  const bill = await Bill.findOne({ tripId });
  if (!bill) {
    return res.json({ exists: false });
  }
  res.json({ exists: true, bill });
};

const getBillPdf = async (req, res) => {
  const bill = await Bill.findById(req.params.id);
  if (!bill || !bill.pdfPath) {
    res.status(404);
    throw new Error('Bill PDF not found');
  }

  res.download(path.join(__dirname, '..', bill.pdfPath));
};

module.exports = {
  billValidation,
  createBill,
  getBills,
  getBillPdf,
  checkBillByTripId,
};
