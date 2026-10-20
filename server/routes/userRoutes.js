const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const User = require('../models/User');

// @desc    Get user data
// @route   GET /api/users/profile
// @access  Private
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findUserById(req.userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// @desc    Save/update user's FCM registration token
// @route   POST /api/users/fcm-token
// @access  Private
router.post('/fcm-token', protect, async (req, res) => {
  try {
    const { fcm_token } = req.body;
    if (fcm_token === undefined) {
      return res.status(400).json({ message: 'fcm_token is required' });
    }

    await User.updateFcmToken(req.userId, fcm_token || null);
    res.json({ message: 'FCM token updated successfully' });
  } catch (error) {
    console.error('Error saving FCM token:', error);
    res.status(500).json({ message: 'Server error saving FCM token' });
  }
});

module.exports = router;
