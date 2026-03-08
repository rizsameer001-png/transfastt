// server/routes/user.routes.js
import express from 'express';
import User    from '../models/User.model.js';
import KYC     from '../models/KYC.model.js';
import { protect } from '../middleware/auth.middleware.js';
import {
  avatarUpload, singleDocUpload,
  uploadToCloudinary, uploadAvatarToCloudinary, deleteFromCloudinary,
} from '../middleware/upload.middleware.js';

const router = express.Router();

// ── GET /api/users/profile ─────────────────────────────────────────────────
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    res.json({ success: true, user });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── PUT /api/users/profile ─────────────────────────────────────────────────
router.put('/profile', protect, async (req, res) => {
  try {
    const allowed = ['firstName', 'lastName', 'phone', 'address', 'dateOfBirth', 'currency'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });
    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true, runValidators: true }).select('-password');
    res.json({ success: true, message: 'Profile updated', user });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── POST /api/users/avatar ─────────────────────────────────────────────────
// User uploads their own profile photo
router.post('/avatar', protect, (req, res, next) => {
  avatarUpload(req, res, err => {
    if (err) return res.status(400).json({ success: false, message: err.message });
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No image uploaded' });

    const user = await User.findById(req.user._id);

    // Delete old avatar from Cloudinary if exists
    if (user.avatarPublicId) {
      await deleteFromCloudinary(user.avatarPublicId, 'image/jpeg');
    }

    // Upload new avatar → Cloudinary (face-crop, 400×400)
    const result = await uploadAvatarToCloudinary(req.file.buffer, req.file.mimetype, user._id);

    user.avatar          = result.url;
    user.avatarPublicId  = result.publicId;
    await user.save();

    res.json({ success: true, message: 'Avatar updated', avatar: result.url });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── DELETE /api/users/avatar ───────────────────────────────────────────────
router.delete('/avatar', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (user.avatarPublicId) {
      await deleteFromCloudinary(user.avatarPublicId, 'image/jpeg');
    }
    user.avatar         = undefined;
    user.avatarPublicId = undefined;
    await user.save();
    res.json({ success: true, message: 'Avatar removed' });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// ── POST /api/users/kyc/document ───────────────────────────────────────────
// User uploads a single extra KYC document (e.g. after rejection, extra proof)
router.post('/kyc/document', protect, (req, res, next) => {
  singleDocUpload(req, res, err => {
    if (err) return res.status(400).json({ success: false, message: err.message });
    next();
  });
}, async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No document uploaded' });

    const { field } = req.body; // e.g. "idFrontImage", "proofOfAddress"
    const allowed   = ['idFrontImage', 'idBackImage', 'selfieImage', 'proofOfAddress'];
    if (!allowed.includes(field)) {
      return res.status(400).json({ success: false, message: `Invalid field. Must be one of: ${allowed.join(', ')}` });
    }

    const kyc = await KYC.findOne({ user: req.user._id });
    if (!kyc) return res.status(404).json({ success: false, message: 'No KYC record found. Please submit KYC first.' });

    // Delete old doc from Cloudinary if exists
    if (kyc[field]?.publicId) {
      await deleteFromCloudinary(kyc[field].publicId, req.file.mimetype);
    }

    // Upload to Cloudinary
    const result = await uploadToCloudinary(
      req.file.buffer,
      req.file.mimetype,
      `transfast/kyc/${req.user._id}`,
      `${req.user._id}_${field}`
    );

    kyc[field] = result;
    await kyc.save();

    res.json({ success: true, message: `${field} uploaded successfully`, document: result });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

export default router;
