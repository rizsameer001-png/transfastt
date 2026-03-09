// lib/core/constants/api_constants.dart

class ApiConstants {
  // ── Base URL ───────────────────────────────────────────────────────────────
  //static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  static const String baseUrl =
      'https://transfastt.onrender.com/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator
  // static const String baseUrl = 'https://your-domain.com/api'; // Production

  static const int connectTimeout = 30000; // 30s (uploads need more time)
  static const int receiveTimeout = 30000;

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String verifyEmail = '/auth/verify-email';

  // ── Users ──────────────────────────────────────────────────────────────────
  static const String userProfile = '/users/profile';
  static const String userAvatar = '/users/avatar'; // POST / DELETE
  static const String userKycDoc =
      '/users/kyc/document'; // POST single doc replace

  // ── Transfers ──────────────────────────────────────────────────────────────
  static const String transferQuote = '/transfers/quote';
  static const String transfers = '/transfers';
  static String transferById(String id) => '/transfers/$id';
  static String cancelTransfer(String id) => '/transfers/$id/cancel';

  // ── Beneficiaries ──────────────────────────────────────────────────────────
  static const String beneficiaries = '/beneficiaries';
  static String beneficiaryById(String id) => '/beneficiaries/$id';

  // ── KYC ────────────────────────────────────────────────────────────────────
  static const String kycSubmit = '/kyc/submit';
  static const String kycStatus = '/kyc/status';

  // ── Exchange ───────────────────────────────────────────────────────────────
  static const String exchangeRates = '/exchange/rates';
  static const String exchangeCountries = '/exchange/countries';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminTransactions = '/admin/transactions';
  static const String adminKyc = '/admin/kyc';
  static const String adminAuditLogs = '/admin/audit-logs';
  static String adminUserStatus(String id) => '/admin/users/$id/status';
  static String adminTxnStatus(String id) => '/admin/transactions/$id/status';
  static String adminKycReview(String id) => '/admin/kyc/$id/review';
  static String adminKycUploadDoc(String kycId) =>
      '/admin/kyc/$kycId/documents'; // POST
  static String adminKycReplaceDoc(String kycId) =>
      '/admin/kyc/$kycId/replace'; // POST
  static String adminKycDeleteDoc(String kycId, String docId) =>
      '/admin/kyc/$kycId/documents/$docId'; // DELETE
}

class AppConstants {
  static const String appName = 'TransFast';
  static const String tokenKey = 'transfast_token';
  static const String userKey = 'transfast_user';
  static const String themeKey = 'transfast_theme';

  static const List<String> sendCurrencies = [
    'USD',
    'GBP',
    'EUR',
    'CAD',
    'AUD'
  ];

  static const Map<String, String> transferPurposes = {
    'family_support': 'Family Support',
    'education': 'Education',
    'medical': 'Medical',
    'business': 'Business',
    'gift': 'Gift',
    'other': 'Other',
  };

  static const Map<String, String> paymentMethods = {
    'debit_card': 'Debit Card',
    'credit_card': 'Credit Card',
    'bank_transfer': 'Bank Transfer',
  };

  static const Map<String, String> payoutMethods = {
    'bank_deposit': 'Bank Deposit',
    'mobile_wallet': 'Mobile Wallet',
    'cash_pickup': 'Cash Pickup',
  };
}
