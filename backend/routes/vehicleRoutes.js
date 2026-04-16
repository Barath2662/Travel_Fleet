const express = require('express');
const {
	vehicleValidation,
	bataRateValidation,
	createVehicle,
	getVehicles,
	updateVehicle,
	deleteVehicle,
	getVehicleBataRates,
	setVehicleBataRate,
} = require('../controllers/vehicleController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();

router.post('/vehicle', protect, authorizeRoles('owner', 'employee'), vehicleValidation, validate, createVehicle);
router.get('/vehicles', protect, getVehicles);
router.put('/vehicle/:id', protect, authorizeRoles('owner', 'employee'), updateVehicle);
router.delete('/vehicle/:id', protect, authorizeRoles('owner', 'employee'), deleteVehicle);
router.get('/vehicle-bata-rates', protect, getVehicleBataRates);
router.put(
	'/vehicle-bata-rates/:category',
	protect,
	authorizeRoles('owner', 'employee'),
	bataRateValidation,
	validate,
	setVehicleBataRate
);

module.exports = router;
