// server/middleware/upload.middleware.js
// All uploads go through Multer memoryStorage → streamed to Cloudinary.
// Nothing is ever written to disk.
import multer from 'multer';
import path        from 'path';
import streamifier from 'streamifier';
import cloudinary  from '../config/cloudinary.js';

// ── Shared file filter ─────────────────────────────────────────────────────
const docFilter = (req, file, cb) => {
  const okExts  = /\.(jpe?g|png|pdf)$/i;
  const okMimes = ['image/jpeg', 'image/png', 'application/pdf'];
  if (okExts.test(path.extname(file.originalname)) && okMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPG, PNG or PDF files are allowed'), false);
  }
};

const imageFilter = (req, file, cb) => {
  const okMimes = ['image/jpeg', 'image/png', 'image/webp'];
  if (okMimes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPG, PNG or WebP images are allowed'), false);
  }
};

// ── Multer instances ───────────────────────────────────────────────────────

// 1. KYC submission — 4 doc fields, 5 MB each
export const kycUpload = multer({
  storage:    multer.memoryStorage(),
  fileFilter: docFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).fields([
  { name: 'idFrontImage',   maxCount: 1 },
  { name: 'idBackImage',    maxCount: 1 },
  { name: 'selfieImage',    maxCount: 1 },
  { name: 'proofOfAddress', maxCount: 1 },
]);

// 2. Avatar / profile photo — single image, 2 MB
export const avatarUpload = multer({
  storage:    multer.memoryStorage(),
  fileFilter: imageFilter,
  limits: { fileSize: 2 * 1024 * 1024 },
}).single('avatar');

// 3. Single generic document upload (admin uploading extra docs for a user)
export const singleDocUpload = multer({
  storage:    multer.memoryStorage(),
  fileFilter: docFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB for admin uploads
}).single('document');

// 4. Multiple documents at once (up to 10) — for admin bulk uploads
export const multiDocUpload = multer({
  storage:    multer.memoryStorage(),
  fileFilter: docFilter,
  limits: { fileSize: 10 * 1024 * 1024 },
}).array('documents', 10);

// ── Core Cloudinary upload helper ──────────────────────────────────────────
export const uploadToCloudinary = (fileBuffer, mimetype, folder, publicId) => {
  return new Promise((resolve, reject) => {
    const resourceType = mimetype === 'application/pdf' ? 'raw' : 'image';
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        public_id:     publicId,
        resource_type: resourceType,
        overwrite:     true,
        ...(resourceType === 'image' && {
          transformation: [
            { quality: 'auto:good' },
            { fetch_format: 'auto' },
            { width: 1600, crop: 'limit' },
          ],
        }),
      },
      (err, result) => {
        if (err) return reject(err);
        resolve({ url: result.secure_url, publicId: result.public_id });
      }
    );
    streamifier.createReadStream(fileBuffer).pipe(uploadStream);
  });
};

// Avatar-specific upload — square crop + smaller size
export const uploadAvatarToCloudinary = (fileBuffer, mimetype, userId) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder:        'transfast/avatars',
        public_id:     `avatar_${userId}`,
        resource_type: 'image',
        overwrite:     true,
        transformation: [
          { width: 400, height: 400, crop: 'fill', gravity: 'face' },
          { quality: 'auto:good' },
          { fetch_format: 'auto' },
        ],
      },
      (err, result) => {
        if (err) return reject(err);
        resolve({ url: result.secure_url, publicId: result.public_id });
      }
    );
    streamifier.createReadStream(fileBuffer).pipe(uploadStream);
  });
};

// ── Delete from Cloudinary ─────────────────────────────────────────────────
export const deleteFromCloudinary = async (publicId, mimetype = 'image/jpeg') => {
  if (!publicId) return;
  try {
    const resourceType = mimetype === 'application/pdf' ? 'raw' : 'image';
    await cloudinary.uploader.destroy(publicId, { resource_type: resourceType });
  } catch (_) {
    console.warn(`[Cloudinary] Could not delete ${publicId}`);
  }
};
