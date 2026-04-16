const express = require('express');
const { param } = require('express-validator');
const { paymentValidation, createPayment, getPayments, updatePayment } = require('../controllers/paymentController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();
const paymentIdParamValidation = [param('id').isMongoId()];

router.post('/payment', protect, authorizeRoles('owner', 'employee'), paymentValidation, validate, createPayment);
router.get('/payments', protect, getPayments);
router.put('/payment/:id', protect, authorizeRoles('owner', 'employee'), paymentIdParamValidation, validate, updatePayment);

module.exports = router;
