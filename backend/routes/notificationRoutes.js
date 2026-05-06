const express = require('express');
const { getNotifications, createNotification, updateNotification, markNotificationRead } = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.get('/notifications', protect, getNotifications);
router.post('/notifications', protect, createNotification);
router.patch('/notifications/:id', protect, updateNotification);
router.put('/notifications/:id/read', protect, markNotificationRead);

module.exports = router;
