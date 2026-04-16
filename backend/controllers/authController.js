const { body } = require('express-validator');
const User = require('../models/User');
const { generateToken } = require('../services/tokenService');

const registerValidation = [
  body('name').notEmpty(),
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('role').optional().isIn(['owner', 'employee', 'driver']),
];

const createUserValidation = [
  body('name').notEmpty(),
  body('email').isEmail(),
  body('password').isLength({ min: 6 }),
  body('role').isIn(['owner', 'employee', 'driver']),
];

const updateUserValidation = [
  body('name').optional().notEmpty(),
  body('email').optional().isEmail(),
  body('password').optional().isLength({ min: 6 }),
  body('role').optional().isIn(['owner', 'employee', 'driver']),
];

const loginValidation = [body('email').isEmail(), body('password').notEmpty()];

const updateProfileValidation = [
  body('name').optional().notEmpty(),
  body('email').optional().isEmail(),
  body('password').optional().isLength({ min: 6 }),
];

const register = async (req, res) => {
  const { name, email, password, role } = req.body;

  const existing = await User.findOne({ email });
  if (existing) {
    res.status(400);
    throw new Error('Email already exists');
  }

  const user = await User.create({ name, email, password, role });

  res.status(201).json({
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    token: generateToken(user._id),
  });
};

const login = async (req, res) => {
  const { email, password, fcmToken } = req.body;
  const user = await User.findOne({ email });

  if (!user || !(await user.matchPassword(password))) {
    res.status(401);
    throw new Error('Invalid email or password');
  }

  if (fcmToken) {
    user.fcmToken = fcmToken;
    await user.save();
  }

  res.json({
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    token: generateToken(user._id),
  });
};

const createUser = async (req, res) => {
  const { name, email, password, role } = req.body;

  const existing = await User.findOne({ email });
  if (existing) {
    res.status(400);
    throw new Error('Email already exists');
  }

  const user = await User.create({ name, email, password, role });

  res.status(201).json({
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
  });
};

const getUsers = async (_req, res) => {
  const users = await User.find().select('-password').sort({ createdAt: -1 });
  res.json(users);
};

const updateUser = async (req, res) => {
  const user = await User.findById(req.params.id);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }

  const { name, email, password, role } = req.body;

  if (email && email !== user.email) {
    const existing = await User.findOne({ email });
    if (existing && String(existing._id) !== String(user._id)) {
      res.status(400);
      throw new Error('Email already exists');
    }
    user.email = email;
  }

  if (name) user.name = name;
  if (password) user.password = password;

  if (role) {
    if (String(req.user._id) === String(user._id) && role !== 'owner') {
      res.status(400);
      throw new Error('Owner cannot change own role from owner');
    }
    user.role = role;
  }

  await user.save();

  res.json({
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
  });
};

const deleteUser = async (req, res) => {
  if (String(req.user._id) === String(req.params.id)) {
    res.status(400);
    throw new Error('Owner cannot delete own account');
  }

  const user = await User.findById(req.params.id);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }

  await user.deleteOne();
  res.json({ message: 'User deleted successfully' });
};

const getProfile = async (req, res) => {
  const user = await User.findById(req.user._id).select('-password');
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }

  res.json({
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
  });
};

const updateProfile = async (req, res) => {
  const { name, email, password } = req.body;

  if (!name && !email && !password) {
    res.status(400);
    throw new Error('At least one field is required to update profile');
  }

  const user = await User.findById(req.user._id);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }

  if (email && email !== user.email) {
    const existing = await User.findOne({ email });
    if (existing && String(existing._id) !== String(user._id)) {
      res.status(400);
      throw new Error('Email already exists');
    }
    user.email = email;
  }

  if (name) user.name = name;
  if (password) user.password = password;

  await user.save();

  res.json({
    _id: user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    token: generateToken(user._id),
  });
};

module.exports = {
  registerValidation,
  createUserValidation,
  updateUserValidation,
  loginValidation,
  updateProfileValidation,
  register,
  login,
  createUser,
  getUsers,
  updateUser,
  deleteUser,
  getProfile,
  updateProfile,
};
