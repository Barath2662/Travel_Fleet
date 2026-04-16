const { body } = require('express-validator');
const Trip = require('../models/Trip');
const Vehicle = require('../models/Vehicle');
const Driver = require('../models/Driver');
const VehicleBataRate = require('../models/VehicleBataRate');

const tripValidation = [
  body('pickupDateTime').isISO8601(),
  body('customerName').notEmpty(),
  body('customerMobile').isLength({ min: 8 }),
  body('pickupLocation').notEmpty(),
  body('placesToVisit').isArray({ min: 1 }),
  body('numberOfDays').isInt({ min: 1 }),
  body('driverId').isMongoId(),
  body('vehicleId').isMongoId(),
];

const assignBataValidation = [body('amount').isFloat({ min: 0 })];
const startTripValidation = [body('startKm').isFloat({ min: 0 })];
const endTripValidation = [
  body('endKm').isFloat({ min: 0 }),
  body('tollApplicable').optional().isBoolean(),
  body('permitApplicable').optional().isBoolean(),
  body('parkingApplicable').optional().isBoolean(),
  body('fastagApplicable').optional().isBoolean(),
  body('tollAmount').optional().isFloat({ min: 0 }),
  body('permitAmount').optional().isFloat({ min: 0 }),
  body('parkingAmount').optional().isFloat({ min: 0 }),
  body('fastagAmount').optional().isFloat({ min: 0 }),
  body('tripNotes').optional().isString(),
  body('routePoints').optional().isArray(),
];
const routePointValidation = [
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
];

const toNumber = (value, fallback = 0) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const ensureDriverTripAccess = async (trip, user) => {
  if (user.role !== 'driver') {
    return true;
  }

  const driver = await Driver.findById(trip.driverId).select('userId');
  if (!driver || String(driver.userId) !== String(user._id)) {
    return false;
  }

  return true;
};

const createTrip = async (req, res) => {
  const payload = req.body;

  const [driver, vehicle] = await Promise.all([
    Driver.findById(payload.driverId),
    Vehicle.findById(payload.vehicleId),
  ]);

  if (!driver || !vehicle) {
    res.status(400);
    throw new Error('Invalid driver or vehicle');
  }

  const rate = await VehicleBataRate.findOne({ category: vehicle.category });
  const defaultBata = rate ? Number(rate.amount) : 0;

  const trip = await Trip.create({
    ...payload,
    driverBataAssigned: defaultBata,
    driverBataAssignedBy: req.user._id,
    driverBataAssignedAt: new Date(),
    createdBy: req.user._id,
  });

  res.status(201).json(trip);
};

const getTrips = async (req, res) => {
  const query = {};

  if (req.query.vehicleId) {
    query.vehicleId = req.query.vehicleId;
  }

  if (req.query.driverId) {
    query.driverId = req.query.driverId;
  }

  if (req.query.status) {
    query.status = req.query.status;
  }

  if (req.query.fromDate || req.query.toDate) {
    query.pickupDateTime = {};
    if (req.query.fromDate) {
      query.pickupDateTime.$gte = new Date(req.query.fromDate);
    }
    if (req.query.toDate) {
      query.pickupDateTime.$lte = new Date(req.query.toDate);
    }
  }

  if (req.user.role === 'driver') {
    const myDriver = await Driver.findOne({ userId: req.user._id }).select('_id');
    if (!myDriver) {
      return res.json([]);
    }
    query.driverId = myDriver._id;
  }

  const trips = await Trip.find(query)
    .populate('driverId', 'name phone')
    .populate('vehicleId', 'number')
    .sort({ createdAt: -1 });
  res.json(trips);
};

const updateTrip = async (req, res) => {
  const trip = await Trip.findById(req.params.id);
  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (trip.status !== 'scheduled') {
    res.status(400);
    throw new Error('Only scheduled trips can be updated');
  }

  Object.assign(trip, req.body);
  await trip.save();
  res.json(trip);
};

const startTrip = async (req, res) => {
  const { startKm } = req.body;
  const trip = await Trip.findById(req.params.id);
  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (trip.status !== 'scheduled') {
    res.status(400);
    throw new Error('Can only start a scheduled trip');
  }

  const canManageTrip = await ensureDriverTripAccess(trip, req.user);
  if (!canManageTrip) {
    res.status(403);
    throw new Error('You can only manage your own assigned trips');
  }

  const vehicle = await Vehicle.findById(trip.vehicleId);
  if (vehicle && Number(startKm) < Number(vehicle.currentKm || 0)) {
    res.status(400);
    throw new Error(`Start KM cannot be less than vehicle current KM (${vehicle.currentKm})`);
  }

  trip.startKm = Number(startKm);
  trip.startTime = new Date();
  trip.status = 'in_progress';
  await trip.save();

  res.json(trip);
};

const endTrip = async (req, res) => {
  const {
    endKm,
    tollApplicable,
    permitApplicable,
    parkingApplicable,
    fastagApplicable,
    tollAmount,
    permitAmount,
    parkingAmount,
    fastagAmount,
    tripNotes,
    routePoints,
  } = req.body;
  const trip = await Trip.findById(req.params.id);

  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (trip.status !== 'in_progress') {
    res.status(400);
    throw new Error('Can only end an in-progress trip');
  }

  const canManageTrip = await ensureDriverTripAccess(trip, req.user);
  if (!canManageTrip) {
    res.status(403);
    throw new Error('You can only manage your own assigned trips');
  }

  if (trip.startKm == null) {
    res.status(400);
    throw new Error('Trip start KM is missing');
  }

  if (Number(endKm) < Number(trip.startKm)) {
    res.status(400);
    throw new Error('End KM cannot be less than start KM');
  }

  trip.endKm = Number(endKm);
  trip.endTime = new Date();
  trip.tollApplicable = Boolean(tollApplicable);
  trip.permitApplicable = Boolean(permitApplicable);
  trip.parkingApplicable = Boolean(parkingApplicable);
  trip.fastagApplicable = Boolean(fastagApplicable);
  trip.tollAmount = Math.max(toNumber(tollAmount), 0);
  trip.permitAmount = Math.max(toNumber(permitAmount), 0);
  trip.parkingAmount = Math.max(toNumber(parkingAmount), 0);
  trip.fastagAmount = Math.max(toNumber(fastagAmount), 0);
  if (typeof tripNotes === 'string') {
    trip.tripNotes = tripNotes.trim();
  }
  if (Array.isArray(routePoints)) {
    trip.routePoints = routePoints
      .map((point) => ({
        latitude: toNumber(point.latitude),
        longitude: toNumber(point.longitude),
        capturedAt: point.capturedAt ? new Date(point.capturedAt) : new Date(),
      }))
      .filter((point) => Number.isFinite(point.latitude) && Number.isFinite(point.longitude));
  }
  trip.status = 'completed';

  await trip.save();

  const vehicle = await Vehicle.findById(trip.vehicleId);
  if (vehicle && Number(endKm) > Number(vehicle.currentKm || 0)) {
    vehicle.currentKm = Number(endKm);
    await vehicle.save();
  }

  const driver = await Driver.findById(trip.driverId);
  if (driver && trip.startTime && trip.endTime) {
    const hours = (new Date(trip.endTime) - new Date(trip.startTime)) / (1000 * 60 * 60);
    driver.totalWorkingHours += Math.max(hours, 0);
    driver.totalWorkingDays += 1;
    driver.totalTripsCompleted += 1;

    if (trip.driverBataAssigned > 0 && !trip.driverBataCredited) {
      driver.totalBataEarned += trip.driverBataAssigned;
      trip.driverBataCredited = true;
      await trip.save();
    }

    await driver.save();
  }

  res.json(trip);
};

const addAdvance = async (req, res) => {
  const { amount } = req.body;
  const trip = await Trip.findById(req.params.id);

  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  const canManageTrip = await ensureDriverTripAccess(trip, req.user);
  if (!canManageTrip) {
    res.status(403);
    throw new Error('You can only manage your own assigned trips');
  }

  trip.advances.push({
    amount,
    addedByRole: req.user.role,
    addedBy: req.user._id,
  });

  await trip.save();
  res.json(trip);
};

const addRoutePoint = async (req, res) => {
  const trip = await Trip.findById(req.params.id);

  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (trip.status !== 'in_progress') {
    res.status(400);
    throw new Error('Route points can only be added to an in-progress trip');
  }

  const canManageTrip = await ensureDriverTripAccess(trip, req.user);
  if (!canManageTrip) {
    res.status(403);
    throw new Error('You can only manage your own assigned trips');
  }

  trip.routePoints.push({
    latitude: Number(req.body.latitude),
    longitude: Number(req.body.longitude),
    capturedAt: new Date(),
  });

  await trip.save();
  res.json(trip);
};

const assignDriverBata = async (req, res) => {
  const { amount } = req.body;
  const trip = await Trip.findById(req.params.id);

  if (!trip) {
    res.status(404);
    throw new Error('Trip not found');
  }

  if (trip.status === 'completed') {
    res.status(400);
    throw new Error('Cannot assign bata after trip completion');
  }

  trip.driverBataAssigned = Number(amount);
  trip.driverBataAssignedBy = req.user._id;
  trip.driverBataAssignedAt = new Date();

  await trip.save();
  res.json(trip);
};

module.exports = {
  tripValidation,
  assignBataValidation,
  startTripValidation,
  endTripValidation,
  routePointValidation,
  createTrip,
  getTrips,
  updateTrip,
  startTrip,
  endTrip,
  addAdvance,
  addRoutePoint,
  assignDriverBata,
};
