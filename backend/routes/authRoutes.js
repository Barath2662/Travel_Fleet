const express = require('express');
const { param } = require('express-validator');
const {
	register,
	login,
	createUser,
	getProfile,
	updateProfile,
	registerValidation,
	loginValidation,
	createUserValidation,
	updateUserValidation,
	getUsers,
	updateUser,
	deleteUser,
	updateProfileValidation,
} = require('../controllers/authController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validationMiddleware');

const router = express.Router();
const userIdParamValidation = [param('id').isMongoId()];

router.post('/register', registerValidation, validate, register);
router.post('/login', loginValidation, validate, login);
router.post('/users', protect, authorizeRoles('owner'), createUserValidation, validate, createUser);
router.get('/users', protect, authorizeRoles('owner'), getUsers);
router.put('/users/:id', protect, authorizeRoles('owner'), userIdParamValidation, updateUserValidation, validate, updateUser);
router.delete('/users/:id', protect, authorizeRoles('owner'), userIdParamValidation, validate, deleteUser);
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfileValidation, validate, updateProfile);

module.exports = router;
