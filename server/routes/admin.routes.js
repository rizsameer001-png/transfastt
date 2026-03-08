// server/routes/admin.routes.js
import express from 'express';
import {
  getDashboardStats, getAllUsers, toggleUserStatus,
  getAllTransactions, updateTransactionStatus,
  reviewKYC, getAllKYC, getAuditLogs,
} from '../controllers/admin.controller.js';
import { protect, authorize } from '../middleware/auth.middleware.js';
import {
  singleDocUpload, multiDocUpload,
  uploadToCloudinary, deleteFromCloudinary,
} from '../middleware/upload.middleware.js';
import KYC  from '../models/KYC.model.js';
import User from '../models/User.model.js';

const router = express.Router();
const adminAccess = [protect, authorize('admin', 'compliance', 'support')];

// ── Dashboard & users ──────────────────────────────────────────────────────
router.get('/dashboard',              ...adminAccess, getDashboardStats);
router.get('/users',                  ...adminAccess, getAllUsers);
router.put('/users/:id/status',       ...adminAccess, toggleUserStatus);

// ── Transactions ───────────────────────────────────────────────────────────
router.get('/transactions',           ...adminAccess, getAllTransactions);
router.put('/transactions/:id/status',...adminAccess, updateTransactionStatus);

// ── KYC review ─────────────────────────────────────────────────────────────
router.get('/kyc',                    ...adminAccess, getAllKYC);
router.put('/kyc/:id/review',         ...adminAccess, reviewKYC);

// ── Admin: upload a supplementary doc to a user's KYC ─────────────────────
// POST /api/admin/kyc/:kycId/documents
// Body (multipart): document (file), label (string), note (optional string)
router.post('/kyc/:kycId/documents',
  ...adminAccess,
  (req, res, next) => {
    singleDocUpload(req, res, err => {
      if (err) return res.status(400).json({ success: false, message: err.message });
      next();
    });
  },
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ success: false, message: 'No document uploaded' });
      const { label = 'Document', note = '' } = req.body;

      const kyc = await KYC.findById(req.params.kycId).populate('user', 'firstName lastName email');
      if (!kyc) return res.status(404).json({ success: false, message: 'KYC record not found' });

      // Upload to Cloudinary under admin folder
      const result = await uploadToCloudinary(
        req.file.buffer,
        req.file.mimetype,
        `transfast/kyc/${kyc.user._id}/admin`,
        `${kyc.user._id}_admin_${Date.now()}`
      );

      kyc.adminDocuments.push({
        label,
        url:        result.url,
        publicId:   result.publicId,
        mimetype:   req.file.mimetype,
        uploadedBy: req.user._id,
        uploadedAt: new Date(),
        note,
      });
      await kyc.save();

      res.json({ success: true, message: 'Document uploaded', document: kyc.adminDocuments.at(-1), kyc });
    } catch (e) {
      res.status(500).json({ success: false, message: e.message });
    }
  }
);

// ── Admin: replace a specific KYC doc field (idFrontImage etc.) ────────────
// POST /api/admin/kyc/:kycId/replace
// Body (multipart): document (file), field (string)
router.post('/kyc/:kycId/replace',
  ...adminAccess,
  (req, res, next) => {
    singleDocUpload(req, res, err => {
      if (err) return res.status(400).json({ success: false, message: err.message });
      next();
    });
  },
  async (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ success: false, message: 'No document uploaded' });
      const { field } = req.body;
      const allowed   = ['idFrontImage', 'idBackImage', 'selfieImage', 'proofOfAddress'];
      if (!allowed.includes(field)) {
        return res.status(400).json({ success: false, message: `Invalid field. Must be one of: ${allowed.join(', ')}` });
      }

      const kyc = await KYC.findById(req.params.kycId);
      if (!kyc) return res.status(404).json({ success: false, message: 'KYC record not found' });

      // Delete old Cloudinary doc
      if (kyc[field]?.publicId) {
        await deleteFromCloudinary(kyc[field].publicId, req.file.mimetype);
      }

      const result = await uploadToCloudinary(
        req.file.buffer,
        req.file.mimetype,
        `transfast/kyc/${kyc.user}`,
        `${kyc.user}_${field}`
      );

      kyc[field] = result;
      await kyc.save();

      res.json({ success: true, message: `${field} replaced`, document: result, kyc });
    } catch (e) {
      res.status(500).json({ success: false, message: e.message });
    }
  }
);

// ── Admin: delete a supplementary doc ─────────────────────────────────────
// DELETE /api/admin/kyc/:kycId/documents/:docId
router.delete('/kyc/:kycId/documents/:docId',
  ...adminAccess,
  async (req, res) => {
    try {
      const kyc = await KYC.findById(req.params.kycId);
      if (!kyc) return res.status(404).json({ success: false, message: 'KYC not found' });

      const doc = kyc.adminDocuments.id(req.params.docId);
      if (!doc) return res.status(404).json({ success: false, message: 'Document not found' });

      await deleteFromCloudinary(doc.publicId, doc.mimetype);
      doc.deleteOne();
      await kyc.save();

      res.json({ success: true, message: 'Document deleted' });
    } catch (e) {
      res.status(500).json({ success: false, message: e.message });
    }
  }
);

// ── Audit logs ─────────────────────────────────────────────────────────────
router.get('/audit-logs', protect, authorize('admin'), getAuditLogs);

export default router;
