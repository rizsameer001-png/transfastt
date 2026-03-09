// server/controllers/exchange.controller.js
import ExchangeRate from '../models/ExchangeRate.model.js';

// @desc  GET /api/exchange/rates?from=USD&to=PKR
//        Returns all rates or a single pair — reads from MongoDB
export const getExchangeRates = async (req, res) => {
  try {
    const { from = 'USD', to } = req.query;

    // We store rates as "1 USD = X currency"
    // If base is not USD, we do a cross-rate: (1/fromRate) * toRate
    const allRates = await ExchangeRate.find({ isActive: true }).lean();

    if (!allRates.length) {
      return res.status(503).json({ success: false, message: 'No exchange rates configured yet. Please ask an admin to set up rates.' });
    }

    // Build { currency: rate } map relative to requested base
    let fromRateUSD = 1; // default: base is USD
    if (from !== 'USD') {
      const fromDoc = allRates.find(r => r.currency === from.toUpperCase());
      if (!fromDoc) return res.status(404).json({ success: false, message: `Base currency ${from} not supported` });
      fromRateUSD = fromDoc.rateFromUSD;
    }

    const rates = {};
    allRates.forEach(r => {
      if (r.currency !== from.toUpperCase()) {
        rates[r.currency] = parseFloat((r.rateFromUSD / fromRateUSD).toFixed(6));
      }
    });

    if (to) {
      const rate = rates[to.toUpperCase()];
      if (!rate) return res.status(404).json({ success: false, message: `Currency pair ${from}/${to} not supported` });
      return res.json({ success: true, from: from.toUpperCase(), to: to.toUpperCase(), rate, timestamp: new Date() });
    }

    res.json({ success: true, base: from.toUpperCase(), rates, timestamp: new Date() });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc  GET /api/exchange/countries
//        Returns active destination countries with flag URLs from Cloudinary
export const getSupportedCountries = async (req, res) => {
  try {
    const countries = await ExchangeRate.find({ isActive: true })
      .sort({ countryName: 1 })
      .select('-updatedBy -__v')
      .lean();

    res.json({ success: true, countries, total: countries.length });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
