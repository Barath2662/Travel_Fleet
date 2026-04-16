const { body } = require('express-validator');
const Vehicle = require('../models/Vehicle');
const VehicleBataRate = require('../models/VehicleBataRate');

const vehicleValidation = [
  body('number').notEmpty(),
  body('category').isIn(['sedan', 'suv', 'mvp', 'van', 'hatchback', 'luxury', 'mini_bus', 'other']),
  body('seats').isInt({ min: 1 }),
  body('fcDate').isISO8601(),
  body('insuranceDate').isISO8601(),
  body('pucDate').isISO8601(),
  body('permitDate').isISO8601(),
  body('nextServiceKm').isNumeric(),
];

const bataRateValidation = [body('amount').isFloat({ min: 0 })];

const createVehicle = async (req, res) => {
  const vehicle = await Vehicle.create(req.body);
  res.status(201).json(vehicle);
};

const getVehicles = async (_req, res) => {
  const vehicles = await Vehicle.find().sort({ createdAt: -1 });
  res.json(vehicles);
};

const updateVehicle = async (req, res) => {
  const vehicle = await Vehicle.findById(req.params.id);
  if (!vehicle) {
    res.status(404);
    throw new Error('Vehicle not found');
  }

  Object.assign(vehicle, req.body);
  await vehicle.save();
  res.json(vehicle);
};

const deleteVehicle = async (req, res) => {
  const vehicle = await Vehicle.findById(req.params.id);
  if (!vehicle) {
    res.status(404);
    throw new Error('Vehicle not found');
  }

  await vehicle.deleteOne();
  res.json({ message: 'Vehicle deleted successfully' });
};

const getVehicleBataRates = async (_req, res) => {
  const rates = await VehicleBataRate.find().sort({ category: 1 });
  res.json(rates);
};

const setVehicleBataRate = async (req, res) => {
  const { category } = req.params;
  const { amount } = req.body;

  const allowed = ['sedan', 'suv', 'mvp', 'van', 'hatchback', 'luxury', 'mini_bus', 'other'];
  if (!allowed.includes(category)) {
    res.status(400);
    throw new Error('Invalid vehicle category');
  }

  const rate = await VehicleBataRate.findOneAndUpdate(
    { category },
    { amount: Number(amount), updatedBy: req.user._id },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );

  res.json(rate);
};

module.exports = {
  vehicleValidation,
  bataRateValidation,
  createVehicle,
  getVehicles,
  updateVehicle,
  deleteVehicle,
  getVehicleBataRates,
  setVehicleBataRate,
};
