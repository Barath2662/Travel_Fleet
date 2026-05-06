const express = require('express');
const { param } = require('express-validator');
const { billValidation, createBill, getBills, getBillPdf, checkBillByTripId } = require('../controllers/billingController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();
const billIdParamValidation = [param('id').isMongoId()];
const tripIdParamValidation = [param('tripId').isMongoId()];

router.post('/bill', protect, authorizeRoles('owner', 'employee'), billValidation, validate, createBill);
router.get('/bills', protect, authorizeRoles('owner', 'employee'), getBills);
router.get('/bills/check/:tripId', protect, authorizeRoles('owner', 'employee'), tripIdParamValidation, validate, checkBillByTripId);
router.get('/bill/:id/pdf', protect, authorizeRoles('owner', 'employee'), billIdParamValidation, validate, getBillPdf);

module.exports = router;
