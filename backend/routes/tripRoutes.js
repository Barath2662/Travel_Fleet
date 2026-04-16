const express = require('express');
const {
  tripValidation,
  createTrip,
  getTrips,
  updateTrip,
  startTripValidation,
  endTripValidation,
  startTrip,
  endTrip,
  addAdvance,
  routePointValidation,
  addRoutePoint,
  assignBataValidation,
  assignDriverBata,
} = require('../controllers/tripController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();

router.post('/trip', protect, authorizeRoles('owner', 'employee'), tripValidation, validate, createTrip);
router.get('/trips', protect, getTrips);
router.put('/trip/:id', protect, authorizeRoles('owner', 'employee'), updateTrip);
router.put('/trip/:id/start', protect, authorizeRoles('driver', 'owner'), startTripValidation, validate, startTrip);
router.put('/trip/:id/end', protect, authorizeRoles('driver', 'owner'), endTripValidation, validate, endTrip);
router.post('/trip/:id/route-point', protect, authorizeRoles('driver', 'owner'), routePointValidation, validate, addRoutePoint);
router.post('/trip/:id/advance', protect, authorizeRoles('owner', 'employee', 'driver'), addAdvance);
router.put('/trip/:id/bata', protect, authorizeRoles('owner', 'employee'), assignBataValidation, validate, assignDriverBata);

module.exports = router;
