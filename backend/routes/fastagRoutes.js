const express = require('express');
const { body } = require('express-validator');
const { requestFastag, setFastagAmount } = require('../controllers/fastagController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();

router.post(
  '/fastag/request',
  protect,
  authorizeRoles('driver', 'owner', 'employee'),
  [body('tripId').isMongoId(), body('applicable').optional().isBoolean()],
  validate,
  requestFastag
);

router.patch(
  '/fastag/amount',
  protect,
  authorizeRoles('owner', 'employee'),
  [
    body('requestId').optional().isMongoId(),
    body('tripId').optional().isMongoId(),
    body('amount').isFloat({ min: 0 }),
  ],
  validate,
  setFastagAmount
);

module.exports = router;
