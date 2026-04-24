require('dotenv').config();
const mongoose = require('mongoose');

const User = require('../models/User');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
const Trip = require('../models/Trip');
const Bill = require('../models/Bill');
const Payment = require('../models/Payment');
const Notification = require('../models/Notification');
const VehicleBataRate = require('../models/VehicleBataRate');

const categories = ['sedan', 'suv', 'mvp', 'van', 'hatchback', 'luxury', 'mini_bus', 'other'];

const getMongoUri = () => {
  const uri = process.env.MONGO_URI || process.env.DATABASE_URL || '';
  if (!uri || !uri.startsWith('mongodb')) {
    throw new Error('Missing valid MongoDB URI. Set MONGO_URI in backend/.env');
  }
  return uri;
};

const seed = async () => {
  const mongoUri = getMongoUri();
  await mongoose.connect(mongoUri);

  console.log('Connected to MongoDB. Dropping existing database...');
  await mongoose.connection.dropDatabase();

  console.log('Creating users...');
  const owner = await User.create({
    name: 'Barath',
    email: 'barath@gmail.com',
    password: 'Owner@123',
    role: 'owner',
  });

  const employee = await User.create({
    name: 'Ajay',
    email: 'ajay@gmail.com',
    password: 'Employee@123',
    role: 'employee',
  });

  const driverUser = await User.create({
    name: 'vikram',
    email: 'vikram@gmail.com',
    password: 'Driver@123',
    role: 'driver',
  });

  console.log('Creating driver profile...');
  const driver = await Driver.create({
    name: 'Primary Driver',
    phone: '9876543210',
    licenseNumber: 'DL-TRAVEL-001',
    salaryPerDay: 1000,
    salaryPerTrip: 400,
    bataRate: 300,
    totalWorkingHours: 8,
    totalWorkingDays: 1,
    totalTripsCompleted: 1,
    totalBataEarned: 500,
    userId: driverUser._id,
    leaves: [
      {
        from: new Date(Date.now() + 24 * 60 * 60 * 1000),
        to: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        reason: 'Personal work',
        status: 'pending',
      },
    ],
  });

  console.log('Creating vehicle and bata rates...');
  const vehicle = await Vehicle.create({
    number: 'KA01AB1234',
    category: 'sedan',
    seats: 4,
    fcDate: new Date('2027-01-01'),
    insuranceDate: new Date('2027-01-15'),
    pucDate: new Date('2026-10-01'),
    permitDate: new Date('2027-02-01'),
    nextServiceKm: 15500,
    currentKm: 12800,
  });

  await VehicleBataRate.insertMany(
    categories.map((category) => ({
      category,
      amount: category === 'sedan' ? 500 : 600,
      updatedBy: owner._id,
    }))
  );

  console.log('Creating trips...');
  const completedTrip = await Trip.create({
    pickupDateTime: new Date(Date.now() - 24 * 60 * 60 * 1000),
    customerName: 'Amit Kumar',
    customerMobile: '9988776655',
    pickupLocation: 'Bangalore Airport',
    placesToVisit: ['MG Road', 'Indiranagar'],
    numberOfDays: 1,
    driverId: driver._id,
    vehicleId: vehicle._id,
    startTime: new Date(Date.now() - 20 * 60 * 60 * 1000),
    endTime: new Date(Date.now() - 16 * 60 * 60 * 1000),
    startKm: 12800,
    endKm: 12920,
    tollApplicable: true,
    tollAmount: 180,
    permitApplicable: false,
    parkingApplicable: true,
    parkingAmount: 120,
    fastagApplicable: true,
    fastagAmount: 100,
    tripNotes: 'Smooth corporate pickup and drop.',
    driverBataAssigned: 500,
    driverBataAssignedBy: owner._id,
    driverBataAssignedAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    driverBataCredited: true,
    status: 'completed',
    advances: [
      {
        amount: 1000,
        addedByRole: 'employee',
        addedBy: employee._id,
      },
    ],
    createdBy: owner._id,
  });

  await Trip.create({
    pickupDateTime: new Date(Date.now() + 12 * 60 * 60 * 1000),
    customerName: 'Neha Sharma',
    customerMobile: '9123456780',
    pickupLocation: 'Whitefield',
    placesToVisit: ['Electronic City'],
    numberOfDays: 1,
    driverId: driver._id,
    vehicleId: vehicle._id,
    driverBataAssigned: 500,
    driverBataAssignedBy: employee._id,
    driverBataAssignedAt: new Date(),
    status: 'scheduled',
    createdBy: employee._id,
  });

  console.log('Creating bill and payment...');
  const bill = await Bill.create({
    tripId: completedTrip._id,
    billDate: new Date(),
    tripDate: completedTrip.pickupDateTime,
    vehicleNumber: vehicle.number,
    tripDetails: 'Airport transfer and city travel',
    startTime: completedTrip.startTime,
    endTime: completedTrip.endTime,
    startKm: completedTrip.startKm,
    endKm: completedTrip.endKm,
    ratePerKm: 25,
    dayRent: 0,
    hourRent: 1200,
    numberOfDays: 1,
    numberOfHours: 4,
    driverBata: 500,
    tollCharges: 180,
    fastagCharges: 100,
    permitCharges: 0,
    parkingCharges: 120,
    advanceReceived: 1000,
    totalKm: 120,
    kmCharge: 3000,
    totalAmount: 5100,
    payableAmount: 4100,
    paymentStatus: 'pending',
  });

  await Payment.create({
    billId: bill._id,
    amount: 2000,
    status: 'pending',
    notes: 'Advance settlement pending final payment',
    updatedBy: employee._id,
  });

  console.log('Creating notifications...');
  await Notification.insertMany([
    {
      userId: owner._id,
      title: 'Database Seeded',
      message: 'Seed data has been loaded successfully.',
      type: 'system',
      isRead: false,
    },
    {
      userId: driverUser._id,
      title: 'Trip Assigned',
      message: 'A new trip has been scheduled for you.',
      type: 'trip',
      isRead: false,
    },
  ]);

  console.log('Reset and seed completed successfully.');
  console.log('Seed logins:');
  console.log('owner@travelfleet.local / Owner@123');
  console.log('employee@travelfleet.local / Employee@123');
  console.log('driver@travelfleet.local / Driver@123');
};

seed()
  .catch((error) => {
    console.error('Reset/seed failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.connection.close().catch(() => undefined);
  });
