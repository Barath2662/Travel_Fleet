const express = require('express');
const { param } = require('express-validator');
const {
	register,
	login,
	createUser,
	getProfile,
	updateProfile,
	applyUserLeave,
	approveUserLeave,
	registerValidation,
	loginValidation,
	createUserValidation,
	updateUserValidation,
	getUsers,
	updateUser,
	deleteUser,
	updateProfileValidation,
	applyLeaveValidation,
	approveLeaveValidation,
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
router.post(
	'/users/:id/leave',
	protect,
	authorizeRoles('owner', 'employee'),
	userIdParamValidation,
	applyLeaveValidation,
	validate,
	applyUserLeave
);
router.put(
	'/users/:id/leave/approve',
	protect,
	authorizeRoles('owner'),
	userIdParamValidation,
	approveLeaveValidation,
	validate,
	approveUserLeave
);

module.exports = router;
