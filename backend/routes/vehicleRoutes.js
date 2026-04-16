const express = require('express');
const { param } = require('express-validator');
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
const vehicleIdParamValidation = [param('id').isMongoId()];

router.post('/vehicle', protect, authorizeRoles('owner', 'employee'), vehicleValidation, validate, createVehicle);
router.get('/vehicles', protect, getVehicles);
router.put('/vehicle/:id', protect, authorizeRoles('owner', 'employee'), vehicleIdParamValidation, validate, updateVehicle);
router.delete('/vehicle/:id', protect, authorizeRoles('owner', 'employee'), vehicleIdParamValidation, validate, deleteVehicle);
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
