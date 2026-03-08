// server/models/KYC.model.js
import mongoose from 'mongoose';

// Reusable sub-schema for a Cloudinary document
const cloudinaryDocSchema = {
  url:      { type: String },
  publicId: { type: String },
};

const kycSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },

  // ── Personal info ──────────────────────────────────────────────────────
  dateOfBirth:   { type: Date,   required: true },
  nationality:   { type: String, required: true },
  occupation:    { type: String },
  sourceOfFunds: {
    type: String,
    enum: ['employment', 'business', 'savings', 'investment', 'inheritance', 'other'],
    required: true,
  },

  // ── Address ────────────────────────────────────────────────────────────
  address: {
    street:     { type: String, required: true },
    city:       { type: String, required: true },
    state:      String,
    postalCode: String,
    country:    { type: String, required: true },
  },

  // ── Identity document ──────────────────────────────────────────────────
  idType: {
    type: String,
    enum: ['passport', 'national_id', 'drivers_license', 'residence_permit'],
    required: true,
  },
  idNumber:    { type: String, required: true },
  idExpiryDate:{ type: Date },

  // ── User-uploaded documents (Cloudinary { url, publicId }) ─────────────
  idFrontImage:   cloudinaryDocSchema,
  idBackImage:    cloudinaryDocSchema,
  selfieImage:    cloudinaryDocSchema,
  proofOfAddress: cloudinaryDocSchema,

  // ── Admin-uploaded supplementary documents ─────────────────────────────
  // Admin can attach any extra docs (e.g. additional ID, bank statement)
  adminDocuments: [{
    label:     { type: String, required: true }, // e.g. "Additional ID", "Bank Statement"
    url:       { type: String, required: true },
    publicId:  { type: String, required: true },
    mimetype:  { type: String },
    uploadedBy:{ type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    uploadedAt:{ type: Date, default: Date.now },
    note:      { type: String }, // admin notes about the document
  }],

  // ── Status ─────────────────────────────────────────────────────────────
  status: {
    type: String,
    enum: ['pending', 'under_review', 'approved', 'rejected'],
    default: 'pending',
  },
  submittedAt:  { type: Date },
  reviewedAt:   { type: Date },
  reviewedBy:   { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rejectedReason:{ type: String },
  notes:        { type: String }, // internal admin notes

  // ── Risk ───────────────────────────────────────────────────────────────
  riskLevel: { type: String, enum: ['low', 'medium', 'high'], default: 'low' },

}, { timestamps: true });

export default mongoose.model('KYC', kycSchema);
