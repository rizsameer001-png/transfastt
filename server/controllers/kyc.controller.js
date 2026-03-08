// server/controllers/kyc.controller.js
import KYC  from '../models/KYC.model.js';
import User from '../models/User.model.js';
import { uploadToCloudinary, deleteFromCloudinary } from '../middleware/upload.middleware.js';

const DOC_FIELDS = ['idFrontImage', 'idBackImage', 'selfieImage', 'proofOfAddress'];

// ── Helper: upload one file to Cloudinary if present in req.files ──────────
const processFile = async (field, files, userId, existingDoc) => {
  const uploaded = files?.[field]?.[0];

  if (uploaded) {
    // Delete old Cloudinary asset before replacing
    if (existingDoc?.publicId) {
      await deleteFromCloudinary(existingDoc.publicId, uploaded.mimetype);
    }
    // Upload new file → returns { url, publicId }
    return uploadToCloudinary(
      uploaded.buffer,
      uploaded.mimetype,
      `transfast/kyc/${userId}`,   // Cloudinary folder
      `${userId}_${field}`         // stable public_id so overwrites cleanly
    );
  }

  // No new file — keep existing Cloudinary doc if present
  if (existingDoc?.url) return existingDoc;

  return null; // not uploaded at all
};

// @desc  Submit / resubmit KYC
export const submitKYC = async (req, res) => {
  try {
    const existingKYC = await KYC.findOne({ user: req.user._id });

    if (existingKYC?.status === 'approved') {
      return res.status(400).json({ success: false, message: 'KYC already approved' });
    }

    // Address comes as JSON string when sent via FormData
    let address = req.body.address;
    if (typeof address === 'string') {
      try { address = JSON.parse(address); } catch { address = {}; }
    }

    // Upload all four documents to Cloudinary in parallel
    const [idFrontImage, idBackImage, selfieImage, proofOfAddress] = await Promise.all([
      processFile('idFrontImage',   req.files, req.user._id, existingKYC?.idFrontImage),
      processFile('idBackImage',    req.files, req.user._id, existingKYC?.idBackImage),
      processFile('selfieImage',    req.files, req.user._id, existingKYC?.selfieImage),
      processFile('proofOfAddress', req.files, req.user._id, existingKYC?.proofOfAddress),
    ]);

    const kycData = {
      user:          req.user._id,
      dateOfBirth:   req.body.dateOfBirth,
      nationality:   req.body.nationality,
      occupation:    req.body.occupation   || '',
      sourceOfFunds: req.body.sourceOfFunds,
      idType:        req.body.idType,
      idNumber:      req.body.idNumber,
      idExpiryDate:  req.body.idExpiryDate || undefined,
      address,
      idFrontImage,
      idBackImage,
      selfieImage,
      proofOfAddress,
      status:      'under_review',
      submittedAt: new Date(),
    };

    let kyc;
    if (existingKYC) {
      kyc = await KYC.findOneAndUpdate({ user: req.user._id }, kycData, { new: true });
    } else {
      kyc = await KYC.create(kycData);
    }

    await User.findByIdAndUpdate(req.user._id, { kycStatus: 'submitted' });

    res.json({ success: true, message: 'KYC submitted for review', kyc });
  } catch (error) {
    console.error('[KYC Submit]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc  Get KYC status + Cloudinary document URLs
export const getKYCStatus = async (req, res) => {
  try {
    const kyc = await KYC.findOne({ user: req.user._id });
    res.json({ success: true, kyc, kycStatus: req.user.kycStatus });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
