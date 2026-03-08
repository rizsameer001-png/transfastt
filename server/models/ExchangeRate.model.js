// server/models/ExchangeRate.model.js
import mongoose from 'mongoose';

const exchangeRateSchema = new mongoose.Schema({
  // Country info
  countryCode: { type: String, required: true, uppercase: true, trim: true }, // e.g. "PK"
  countryName: { type: String, required: true, trim: true },                  // e.g. "Pakistan"

  // Currency
  currency:     { type: String, required: true, uppercase: true, trim: true }, // e.g. "PKR"
  currencyName: { type: String, trim: true },                                  // e.g. "Pakistani Rupee"

  // Rate vs USD (1 USD = X currency)
  rateFromUSD: { type: Number, required: true, min: 0 },

  // Flag image stored on Cloudinary
  flag: {
    url:      { type: String }, // Cloudinary secure URL
    publicId: { type: String }, // For deletion/replacement
  },

  // Payout methods available for this corridor
  payoutMethods: [{
    type: String,
    enum: ['bank_deposit', 'cash_pickup', 'mobile_wallet'],
  }],

  // Transfer fee (percentage)
  feePercent: { type: Number, default: 2.5, min: 0 },

  // Min/max transfer amounts (in USD)
  minAmount: { type: Number, default: 10 },
  maxAmount: { type: Number, default: 10000 },

  isActive: { type: Boolean, default: true },

  // Who last updated the rate
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

}, { timestamps: true });

// Unique per currency
exchangeRateSchema.index({ currency: 1 }, { unique: true });
exchangeRateSchema.index({ countryCode: 1 });
exchangeRateSchema.index({ isActive: 1 });

export default mongoose.model('ExchangeRate', exchangeRateSchema);
