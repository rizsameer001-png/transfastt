// lib/core/api/api_services.dart
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../constants/api_constants.dart';

// ── Auth ───────────────────────────────────────────────────────────────────
class AuthApiService extends BaseApiService {
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) =>
      post(ApiConstants.register, data: data);
  Future<Map<String, dynamic>> login(String email, String password) =>
      post(ApiConstants.login, data: {'email': email, 'password': password});
  Future<Map<String, dynamic>> getMe() => get(ApiConstants.me);
  Future<Map<String, dynamic>> forgotPassword(String email) =>
      post(ApiConstants.forgotPassword, data: {'email': email});
  Future<Map<String, dynamic>> changePassword(String current, String newPass) =>
      put(ApiConstants.changePassword,
          data: {'currentPassword': current, 'newPassword': newPass});
}

// ── User ───────────────────────────────────────────────────────────────────
class UserApiService extends BaseApiService {
  Future<Map<String, dynamic>> getProfile() => get(ApiConstants.userProfile);
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) =>
      put(ApiConstants.userProfile, data: data);

  /// Upload / replace the user's avatar photo.
  /// [imagePath] = absolute path to the picked image file.
  Future<Map<String, dynamic>> uploadAvatar(String imagePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
    });
    return post(ApiConstants.userAvatar, data: formData);
  }

  /// Remove the current avatar.
  Future<Map<String, dynamic>> deleteAvatar() => delete(ApiConstants.userAvatar);

  /// Replace a single KYC document field (e.g. just the selfie).
  /// [field] one of: idFrontImage | idBackImage | selfieImage | proofOfAddress
  Future<Map<String, dynamic>> uploadKycDocument(String field, String filePath) async {
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
      'field': field,
    });
    return post(ApiConstants.userKycDoc, data: formData);
  }
}

// ── Transfer ───────────────────────────────────────────────────────────────
class TransferApiService extends BaseApiService {
  Future<Map<String, dynamic>> getQuote({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    String? payoutMethod,
  }) =>
      get(ApiConstants.transferQuote, params: {
        'amount': amount,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        if (payoutMethod != null) 'payoutMethod': payoutMethod,
      });

  Future<Map<String, dynamic>> initiateTransfer(Map<String, dynamic> data) =>
      post(ApiConstants.transfers, data: data);

  Future<Map<String, dynamic>> getTransfers({int page = 1, int limit = 10, String? status}) =>
      get(ApiConstants.transfers, params: {
        'page': page, 'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      });

  Future<Map<String, dynamic>> getTransferById(String id) =>
      get(ApiConstants.transferById(id));

  Future<Map<String, dynamic>> cancelTransfer(String id) =>
      put(ApiConstants.cancelTransfer(id));
}

// ── Beneficiary ────────────────────────────────────────────────────────────
class BeneficiaryApiService extends BaseApiService {
  Future<Map<String, dynamic>> getBeneficiaries() =>
      get(ApiConstants.beneficiaries);
  Future<Map<String, dynamic>> addBeneficiary(Map<String, dynamic> data) =>
      post(ApiConstants.beneficiaries, data: data);
  Future<Map<String, dynamic>> updateBeneficiary(String id, Map<String, dynamic> data) =>
      put(ApiConstants.beneficiaryById(id), data: data);
  Future<Map<String, dynamic>> deleteBeneficiary(String id) =>
      delete(ApiConstants.beneficiaryById(id));
}

// ── KYC ────────────────────────────────────────────────────────────────────
class KycApiService extends BaseApiService {
  /// Full KYC form submission — multipart.
  /// [fields] = text fields, [files] = { fieldName: filePath }
  Future<Map<String, dynamic>> submitKyc(
    Map<String, String> fields, {
    Map<String, String> files = const {},
  }) async {
    final formData = FormData();
    fields.forEach((k, v) => formData.fields.add(MapEntry(k, v)));
    for (final entry in files.entries) {
      if (entry.value.isNotEmpty) {
        formData.files.add(MapEntry(
          entry.key,
          await MultipartFile.fromFile(entry.value,
              filename: entry.value.split('/').last),
        ));
      }
    }
    return post(ApiConstants.kycSubmit, data: formData);
  }

  Future<Map<String, dynamic>> getKycStatus() => get(ApiConstants.kycStatus);
}

// ── Exchange ───────────────────────────────────────────────────────────────
class ExchangeApiService extends BaseApiService {
  Future<Map<String, dynamic>> getRates({String from = 'USD'}) =>
      get(ApiConstants.exchangeRates, params: {'from': from});
  Future<Map<String, dynamic>> getCountries() =>
      get(ApiConstants.exchangeCountries);
}

// ── Admin ──────────────────────────────────────────────────────────────────
class AdminApiService extends BaseApiService {
  Future<Map<String, dynamic>> getDashboard() => get(ApiConstants.adminDashboard);

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search, String? kycStatus}) =>
      get(ApiConstants.adminUsers, params: {
        'page': page, 'limit': 20,
        if (search != null && search.isNotEmpty) 'search': search,
        if (kycStatus != null && kycStatus.isNotEmpty) 'kycStatus': kycStatus,
      });

  Future<Map<String, dynamic>> toggleUserStatus(String id, String action, {String? reason}) =>
      put(ApiConstants.adminUserStatus(id),
          data: {'action': action, if (reason != null) 'reason': reason});

  Future<Map<String, dynamic>> getTransactions({int page = 1, String? status, bool flagged = false}) =>
      get(ApiConstants.adminTransactions, params: {
        'page': page, 'limit': 20,
        if (status != null && status.isNotEmpty) 'status': status,
        if (flagged) 'flagged': true,
      });

  Future<Map<String, dynamic>> updateTransactionStatus(String id, String status, {String? note}) =>
      put(ApiConstants.adminTxnStatus(id),
          data: {'status': status, if (note != null) 'note': note});

  Future<Map<String, dynamic>> getKycList({int page = 1, String status = 'under_review'}) =>
      get(ApiConstants.adminKyc, params: {'page': page, 'status': status});

  Future<Map<String, dynamic>> reviewKyc(String id, String action, {String? reason}) =>
      put(ApiConstants.adminKycReview(id),
          data: {'action': action, if (reason != null) 'reason': reason});

  Future<Map<String, dynamic>> getAuditLogs({int page = 1}) =>
      get(ApiConstants.adminAuditLogs, params: {'page': page, 'limit': 30});

  // ── Admin doc upload ───────────────────────────────────────────────────────

  /// Upload a supplementary doc to a user's KYC (admin-added).
  Future<Map<String, dynamic>> uploadKycDoc(
      String kycId, String filePath, String label, {String? note}) async {
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(filePath,
          filename: filePath.split('/').last),
      'label': label,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return post(ApiConstants.adminKycUploadDoc(kycId), data: formData);
  }

  /// Admin replaces a specific user doc field.
  Future<Map<String, dynamic>> replaceKycDoc(
      String kycId, String field, String filePath) async {
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(filePath,
          filename: filePath.split('/').last),
      'field': field,
    });
    return post(ApiConstants.adminKycReplaceDoc(kycId), data: formData);
  }

  /// Delete an admin-uploaded supplementary doc.
  Future<Map<String, dynamic>> deleteKycDoc(String kycId, String docId) =>
      delete(ApiConstants.adminKycDeleteDoc(kycId, docId));
}
