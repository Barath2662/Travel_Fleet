const express = require('express');
const { param } = require('express-validator');
const { billValidation, createBill, getBills, getBillPdf } = require('../controllers/billingController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();
const billIdParamValidation = [param('id').isMongoId()];

router.post('/bill', protect, authorizeRoles('owner', 'employee'), billValidation, validate, createBill);
router.get('/bills', protect, getBills);
router.get('/bill/:id/pdf', protect, billIdParamValidation, validate, getBillPdf);

module.exports = router;
