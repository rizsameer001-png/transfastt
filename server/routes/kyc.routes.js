// server/routes/kyc.routes.js
import express from 'express';
import { submitKYC, getKYCStatus } from '../controllers/kyc.controller.js';
import { protect } from '../middleware/auth.middleware.js';
import { kycUpload } from '../middleware/upload.middleware.js';

const router = express.Router();

router.post('/submit', protect, kycUpload, submitKYC);
router.get('/status',  protect, getKYCStatus);

export default router;
