const { body } = require('express-validator');
const Driver = require('../models/Driver');
const User = require('../models/User');
const { getOwnerUser, findOrCreatePendingNotification, completeNotificationByEntity } = require('../services/notificationService');

const driverValidation = [
  body('name').notEmpty(),
  body('phone').notEmpty(),
  body('licenseNumber').notEmpty(),
  body('email').optional().isEmail(),
  body('password').optional().isLength({ min: 6 }),
];

const approveLeaveValidation = [
  body('leaveId').isMongoId(),
  body('status').isIn(['pending', 'approved', 'rejected']),
];

const hasLeaveOverlap = (leaves, fromDate, toDate) => {
  return (leaves || []).some((leave) => {
    if (!leave || leave.status === 'rejected') return false;
    const leaveStart = new Date(leave.from);
    const leaveEnd = new Date(leave.to);
    return fromDate <= leaveEnd && toDate >= leaveStart;
  });
};

const createDriver = async (req, res) => {
  const payload = { ...req.body };
  let user = null;

  if (payload.email || payload.password) {
    if (!payload.email || !payload.password) {
      res.status(400);
      throw new Error('Both email and password are required to create driver login');
    }

    const existingUser = await User.findOne({ email: payload.email });
    if (existingUser) {
      res.status(400);
      throw new Error('Driver login email already exists');
    }

    user = await User.create({
      name: payload.name,
      email: payload.email,
      password: payload.password,
      role: 'driver',
    });
  }

  delete payload.email;
  delete payload.password;

  if (user) {
    payload.userId = user._id;
  }

  const driver = await Driver.create(payload);
  res.status(201).json(driver);
};

const getDrivers = async (req, res) => {
  if (req.user.role === 'driver') {
    const ownDriver = await Driver.findOne({ userId: req.user._id }).populate('userId', 'name email role');
    return res.json(ownDriver ? [ownDriver] : []);
  }

  const drivers = await Driver.find().populate('userId', 'name email role').sort({ createdAt: -1 });
  res.json(drivers);
};

const updateDriver = async (req, res) => {
  const driver = await Driver.findById(req.params.id);
  if (!driver) {
    res.status(404);
    throw new Error('Driver not found');
  }

  const allowed = ['name', 'phone', 'licenseNumber', 'salaryPerDay', 'salaryPerTrip', 'bataRate'];
  allowed.forEach((field) => {
    if (req.body[field] !== undefined) {
      driver[field] = req.body[field];
    }
  });

  await driver.save();

  if (driver.userId) {
    const linkedUser = await User.findById(driver.userId);
    if (linkedUser) {
      if (req.body.name) linkedUser.name = req.body.name;
      if (req.body.email) {
        const existing = await User.findOne({ email: req.body.email });
        if (existing && String(existing._id) !== String(linkedUser._id)) {
          res.status(400);
          throw new Error('Email already exists');
        }
        linkedUser.email = req.body.email;
      }
      if (req.body.password) linkedUser.password = req.body.password;
      await linkedUser.save();
    }
  }

  const updated = await Driver.findById(driver._id).populate('userId', 'name email role');
  res.json(updated);
};

const deleteDriver = async (req, res) => {
  const driver = await Driver.findById(req.params.id);
  if (!driver) {
    res.status(404);
    throw new Error('Driver not found');
  }

  const linkedUserId = driver.userId;
  await driver.deleteOne();

  if (linkedUserId) {
    await User.findByIdAndDelete(linkedUserId);
  }

  res.json({ message: 'Driver deleted successfully' });
};

const applyLeave = async (req, res) => {
  const { from, to, reason } = req.body;
  if (!from || !to || !reason || !String(reason).trim()) {
    res.status(400);
    throw new Error('from, to and reason are required');
  }

  const fromDate = new Date(from);
  const toDate = new Date(to);
  if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime()) || toDate < fromDate) {
    res.status(400);
    throw new Error('Invalid leave date range');
  }

  const driver = await Driver.findById(req.params.id);

  if (!driver) {
    res.status(404);
    throw new Error('Driver not found');
  }

  if (req.user.role === 'driver' && String(driver.userId) !== String(req.user._id)) {
    res.status(403);
    throw new Error('Drivers can apply leave only for their own profile');
  }

  if (hasLeaveOverlap(driver.leaves, fromDate, toDate)) {
    res.status(400);
    throw new Error('Leave request overlaps with an existing request');
  }

  driver.leaves.push({ from: fromDate, to: toDate, reason: String(reason).trim() });
  await driver.save();

  const owner = await getOwnerUser();
  if (owner) {
    const latestLeave = driver.leaves[driver.leaves.length - 1];
    if (latestLeave) {
      await findOrCreatePendingNotification({
        userId: owner._id,
        assignedTo: owner._id,
        type: 'leave_request_driver',
        relatedEntityId: latestLeave._id,
        title: 'Leave request pending approval',
        message: `Driver ${driver.name} requested leave from ${fromDate.toDateString()} to ${toDate.toDateString()}.`,
        meta: {
          driverId: driver._id,
          leaveId: latestLeave._id,
          from: fromDate,
          to: toDate,
          reason: String(reason).trim(),
        },
        actionRequired: true,
      });
    }
  }
  res.json(driver);
};

const approveLeave = async (req, res) => {
  const { leaveId, status } = req.body;
  const driver = await Driver.findById(req.params.id);

  if (!driver) {
    res.status(404);
    throw new Error('Driver not found');
  }

  const leave = driver.leaves.id(leaveId);
  if (!leave) {
    res.status(404);
    throw new Error('Leave request not found');
  }

  leave.status = status;
  leave.approvedBy = req.user._id;
  await driver.save();

  await completeNotificationByEntity({
    type: 'leave_request_driver',
    relatedEntityId: leave._id,
  });

  res.json(driver);
};

const getPayrollSummary = async (req, res) => {
  const driver = await Driver.findById(req.params.id);
  if (!driver) {
    res.status(404);
    throw new Error('Driver not found');
  }

  if (req.user.role === 'driver' && String(driver.userId) !== String(req.user._id)) {
    res.status(403);
    throw new Error('Drivers can view payroll only for their own profile');
  }

  const salaryFromDays = driver.totalWorkingDays * (driver.salaryPerDay || 0);
  const salaryFromHours = driver.totalWorkingHours * ((driver.salaryPerDay || 0) / 8);
  const tripSalary = driver.totalTripsCompleted * (driver.salaryPerTrip || 0);
  const totalBata = driver.totalBataEarned || 0;
  const approvedLeaveCount = driver.leaves.filter((l) => l.status === 'approved').length;
  const pendingLeaveCount = driver.leaves.filter((l) => l.status === 'pending').length;
  const leaveDeduction = approvedLeaveCount * (driver.salaryPerDay || 0);
  const estimatedSalary = Math.max(Math.max(salaryFromDays, salaryFromHours) - leaveDeduction, 0);
  const grossPayable = estimatedSalary + tripSalary + totalBata;

  res.json({
    driverId: driver._id,
    driverName: driver.name,
    totalWorkingDays: driver.totalWorkingDays,
    totalWorkingHours: driver.totalWorkingHours,
    totalTripsCompleted: driver.totalTripsCompleted,
    salaryFromDays,
    salaryFromHours,
    tripSalary,
    totalBata,
    approvedLeaveCount,
    pendingLeaveCount,
    leaveDeduction,
    estimatedSalary,
    grossPayable,
  });
};

module.exports = {
  driverValidation,
  approveLeaveValidation,
  createDriver,
  getDrivers,
  updateDriver,
  deleteDriver,
  applyLeave,
  approveLeave,
  getPayrollSummary,
};
