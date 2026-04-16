const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  if (!process.env.JWT_SECRET) {
    res.status(500);
    throw new Error('Server misconfiguration: JWT secret is missing');
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401);
    throw new Error('Unauthorized: missing token');
  }

  const token = authHeader.slice(7).trim();
  if (!token) {
    res.status(401);
    throw new Error('Unauthorized: invalid token');
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = await User.findById(decoded.id).select('-password');
    if (!req.user) {
      res.status(401);
      throw new Error('Unauthorized: user not found');
    }
    next();
  } catch (error) {
    res.status(401);
    if (error.name === 'TokenExpiredError') {
      throw new Error('Unauthorized: token expired');
    }
    throw new Error('Unauthorized: invalid token');
  }
};

const authorizeRoles = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    res.status(403);
    throw new Error('Forbidden: insufficient permissions');
  }
  next();
};

module.exports = { protect, authorizeRoles };
