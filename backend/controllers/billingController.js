const { body } = require('express-validator');
const path = require('path');
const Bill = require('../models/Bill');
const Trip = require('../models/Trip');
const { generateInvoicePdf } = require('../services/pdfService');

const billValidation = [
  body('tripId').optional({ checkFalsy: true }).isMongoId(),
  body('billDate').optional({ checkFalsy: true }).isISO8601(),
  body('tripDate').optional({ checkFalsy: true }).isISO8601(),
  body('startKm').optional({ checkFalsy: true }).isNumeric(),
  body('endKm').optional({ checkFalsy: true }).isNumeric(),
  body('ratePerKm').optional({ checkFalsy: true }).isNumeric(),
  body('dayRent').optional({ checkFalsy: true }).isNumeric(),
  body('hourRent').optional({ checkFalsy: true }).isNumeric(),
  body('numberOfDays').optional({ checkFalsy: true }).isNumeric(),
  body('numberOfHours').optional({ checkFalsy: true }).isNumeric(),
  body('driverBata').optional({ checkFalsy: true }).isNumeric(),
  body('tollCharges').optional({ checkFalsy: true }).isNumeric(),
  body('permitCharges').optional({ checkFalsy: true }).isNumeric(),
  body('parkingCharges').optional({ checkFalsy: true }).isNumeric(),
  body('advanceReceived').optional({ checkFalsy: true }).isNumeric(),
];

const toNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const computeBillFields = (payload) => {
  const totalKm = Math.max(toNumber(payload.endKm) - toNumber(payload.startKm), 0);
  const kmCharge = totalKm * toNumber(payload.ratePerKm);

  const totalAmount =
    kmCharge +
    toNumber(payload.dayRent) +
    toNumber(payload.hourRent) +
    toNumber(payload.driverBata) +
    toNumber(payload.tollCharges) +
    toNumber(payload.permitCharges) +
    toNumber(payload.parkingCharges);

  const payableAmount = totalAmount - toNumber(payload.advanceReceived);

  return { totalKm, kmCharge, totalAmount, payableAmount };
};

const createBill = async (req, res) => {
  const payload = req.body;

  const trip = payload.tripId ? await Trip.findById(payload.tripId) : null;

  const sanitizedPayload = {
    ...(payload.tripId ? { tripId: payload.tripId } : {}),
    billDate: payload.billDate || new Date(),
    tripDate: payload.tripDate || payload.billDate || trip?.pickupDateTime || new Date(),
    vehicleNumber: payload.vehicleNumber || 'N/A',
    tripDetails: payload.tripDetails || 'Business trip',
    startTime: payload.startTime || trip?.startTime,
    endTime: payload.endTime || trip?.endTime,
    startKm: Math.max(toNumber(payload.startKm, toNumber(trip?.startKm, 0)), 0),
    endKm: Math.max(toNumber(payload.endKm, toNumber(trip?.endKm, 0)), 0),
    ratePerKm: Math.max(toNumber(payload.ratePerKm), 0),
    dayRent: Math.max(toNumber(payload.dayRent), 0),
    hourRent: Math.max(toNumber(payload.hourRent), 0),
    numberOfDays: Math.max(toNumber(payload.numberOfDays), 0),
    numberOfHours: Math.max(toNumber(payload.numberOfHours), 0),
    driverBata: Math.max(toNumber(payload.driverBata), 0),
    tollCharges: Math.max(toNumber(payload.tollCharges), 0),
    permitCharges: Math.max(toNumber(payload.permitCharges), 0),
    parkingCharges: Math.max(toNumber(payload.parkingCharges), 0),
    advanceReceived: Math.max(toNumber(payload.advanceReceived), 0),
  };

  const totals = computeBillFields(sanitizedPayload);

  const bill = await Bill.create({
    ...sanitizedPayload,
    ...totals,
  });

  const pdf = await generateInvoicePdf(bill);
  bill.pdfPath = pdf.relativePath;
  await bill.save();

  res.status(201).json(bill);
};

const getBills = async (_req, res) => {
  const bills = await Bill.find().populate('tripId').sort({ createdAt: -1 });
  res.json(bills);
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
};
