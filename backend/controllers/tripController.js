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

const runWithOptionalTransaction = async (session, work) => {
  try {
    await session.withTransaction(work);
  } catch (error) {
    if (String(error.message || '').includes('Transaction numbers are only allowed')) {
      await work();
      return;
    }
    throw error;
  }
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
    if (!/^[a-fA-F0-9]{24}$/.test(req.query.vehicleId)) {
      res.status(400);
      throw new Error('Invalid vehicleId');
    }
    query.vehicleId = req.query.vehicleId;
  }

  if (req.query.driverId) {
    if (!/^[a-fA-F0-9]{24}$/.test(req.query.driverId)) {
      res.status(400);
      throw new Error('Invalid driverId');
    }
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

  const started = await Trip.findOneAndUpdate(
    { _id: trip._id, status: 'scheduled' },
    { $set: { startKm: Number(startKm), startTime: new Date(), status: 'in_progress' } },
    { new: true }
  );

  if (!started) {
    res.status(409);
    throw new Error('Trip already started or completed');
  }

  res.json(started);
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

  const session = await Trip.startSession();
  let completedTrip = null;

  try {
    await runWithOptionalTransaction(session, async () => {
      const lockedTrip = await Trip.findOne({ _id: trip._id, status: 'in_progress' }).session(session);
      if (!lockedTrip) {
        res.status(409);
        throw new Error('Trip already completed or not in progress');
      }

      if (Number(endKm) < Number(lockedTrip.startKm)) {
        res.status(400);
        throw new Error('End KM cannot be less than start KM');
      }

      lockedTrip.endKm = Number(endKm);
      lockedTrip.endTime = new Date();
      lockedTrip.tollApplicable = Boolean(tollApplicable);
      lockedTrip.permitApplicable = Boolean(permitApplicable);
      lockedTrip.parkingApplicable = Boolean(parkingApplicable);
      lockedTrip.fastagApplicable = Boolean(fastagApplicable);
      lockedTrip.tollAmount = Math.max(toNumber(tollAmount), 0);
      lockedTrip.permitAmount = Math.max(toNumber(permitAmount), 0);
      lockedTrip.parkingAmount = Math.max(toNumber(parkingAmount), 0);
      lockedTrip.fastagAmount = Math.max(toNumber(fastagAmount), 0);
      if (typeof tripNotes === 'string') {
        lockedTrip.tripNotes = tripNotes.trim();
      }
      if (Array.isArray(routePoints)) {
        lockedTrip.routePoints = routePoints
          .map((point) => ({
            latitude: toNumber(point.latitude),
            longitude: toNumber(point.longitude),
            capturedAt: point.capturedAt ? new Date(point.capturedAt) : new Date(),
          }))
          .filter((point) => Number.isFinite(point.latitude) && Number.isFinite(point.longitude));
      }
      lockedTrip.status = 'completed';

      const driver = await Driver.findById(lockedTrip.driverId).session(session);
      const vehicle = await Vehicle.findById(lockedTrip.vehicleId).session(session);

      if (vehicle && Number(endKm) > Number(vehicle.currentKm || 0)) {
        vehicle.currentKm = Number(endKm);
        await vehicle.save({ session: session.inTransaction() ? session : undefined });
      }

      if (driver && lockedTrip.startTime && lockedTrip.endTime) {
        const hours = (new Date(lockedTrip.endTime) - new Date(lockedTrip.startTime)) / (1000 * 60 * 60);
        driver.totalWorkingHours += Math.max(hours, 0);
        driver.totalWorkingDays += 1;
        driver.totalTripsCompleted += 1;

        if (lockedTrip.driverBataAssigned > 0 && !lockedTrip.driverBataCredited) {
          driver.totalBataEarned += lockedTrip.driverBataAssigned;
          lockedTrip.driverBataCredited = true;
        }

        await driver.save({ session: session.inTransaction() ? session : undefined });
      }

      await lockedTrip.save({ session: session.inTransaction() ? session : undefined });
      completedTrip = lockedTrip;
    });
  } finally {
    await session.endSession();
  }

  res.json(completedTrip);
};

const addAdvance = async (req, res) => {
  const { amount } = req.body;
  if (!Number.isFinite(Number(amount)) || Number(amount) <= 0) {
    res.status(400);
    throw new Error('Advance amount must be a positive number');
  }

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
    amount: Number(amount),
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
