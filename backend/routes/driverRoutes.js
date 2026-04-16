const express = require('express');
const { param } = require('express-validator');
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
const driverIdParamValidation = [param('id').isMongoId()];

router.post('/driver', protect, authorizeRoles('owner', 'employee'), driverValidation, validate, createDriver);
router.get('/drivers', protect, getDrivers);
router.put('/driver/:id', protect, authorizeRoles('owner', 'employee'), driverIdParamValidation, validate, updateDriver);
router.delete('/driver/:id', protect, authorizeRoles('owner', 'employee'), driverIdParamValidation, validate, deleteDriver);
router.post('/driver/:id/leave', protect, authorizeRoles('driver', 'employee'), driverIdParamValidation, validate, applyLeave);
router.put('/driver/:id/leave/approve', protect, authorizeRoles('owner', 'employee'), driverIdParamValidation, approveLeaveValidation, validate, approveLeave);
router.get('/driver/:id/payroll', protect, authorizeRoles('owner', 'employee', 'driver'), driverIdParamValidation, validate, getPayrollSummary);

module.exports = router;
