const express = require('express');
const {
  driverValidation,
  approveLeaveValidation,
  createDriver,
  getDrivers,
  updateDriver,
  deleteDriver,
  applyLeave,
  approveLeave,
  getPayrollSummary,
} = require('../controllers/driverController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();

router.post('/driver', protect, authorizeRoles('owner', 'employee'), driverValidation, validate, createDriver);
router.get('/drivers', protect, getDrivers);
router.put('/driver/:id', protect, authorizeRoles('owner', 'employee'), updateDriver);
router.delete('/driver/:id', protect, authorizeRoles('owner', 'employee'), deleteDriver);
router.post('/driver/:id/leave', protect, authorizeRoles('driver', 'employee'), applyLeave);
router.put('/driver/:id/leave/approve', protect, authorizeRoles('owner', 'employee'), approveLeaveValidation, validate, approveLeave);
router.get('/driver/:id/payroll', protect, authorizeRoles('owner', 'employee', 'driver'), getPayrollSummary);

module.exports = router;
