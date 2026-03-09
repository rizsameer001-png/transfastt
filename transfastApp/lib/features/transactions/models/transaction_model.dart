// lib/features/transactions/models/transaction_model.dart

class TransactionModel {
  final String id;
  final String transactionId;
  final double sendAmount;
  final String sendCurrency;
  final double receiveAmount;
  final String receiveCurrency;
  final double exchangeRate;
  final double transferFee;
  final double totalDeducted;
  final String payoutMethod;
  final String paymentMethod;
  final String status;
  final String sendCountry;
  final String receiveCountry;
  final String transferPurpose;
  final bool isFlagged;
  final String? flaggedReason;
  final String? senderNote;
  final String? estimatedDelivery;
  final String? completedAt;
  final String createdAt;
  final Map<String, dynamic>? beneficiary;
  final List<Map<String, dynamic>> statusHistory;

  const TransactionModel({
    required this.id,
    required this.transactionId,
    required this.sendAmount,
    required this.sendCurrency,
    required this.receiveAmount,
    required this.receiveCurrency,
    required this.exchangeRate,
    required this.transferFee,
    required this.totalDeducted,
    required this.payoutMethod,
    required this.paymentMethod,
    required this.status,
    required this.sendCountry,
    required this.receiveCountry,
    required this.transferPurpose,
    required this.isFlagged,
    this.flaggedReason,
    this.senderNote,
    this.estimatedDelivery,
    this.completedAt,
    required this.createdAt,
    this.beneficiary,
    required this.statusHistory,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      sendAmount: (json['sendAmount'] as num?)?.toDouble() ?? 0,
      sendCurrency: json['sendCurrency'] ?? 'USD',
      receiveAmount: (json['receiveAmount'] as num?)?.toDouble() ?? 0,
      receiveCurrency: json['receiveCurrency'] ?? '',
      exchangeRate: (json['exchangeRate'] as num?)?.toDouble() ?? 0,
      transferFee: (json['transferFee'] as num?)?.toDouble() ?? 0,
      totalDeducted: (json['totalDeducted'] as num?)?.toDouble() ?? 0,
      payoutMethod: json['payoutMethod'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? 'pending',
      sendCountry: json['sendCountry'] ?? '',
      receiveCountry: json['receiveCountry'] ?? '',
      transferPurpose: json['transferPurpose'] ?? '',
      isFlagged: json['isFlagged'] ?? false,
      flaggedReason: json['flaggedReason'],
      senderNote: json['senderNote'],
      estimatedDelivery: json['estimatedDelivery'],
      completedAt: json['completedAt'],
      createdAt: json['createdAt'] ?? '',
      beneficiary: json['beneficiary'] as Map<String, dynamic>?,
      statusHistory: (json['statusHistory'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  String get beneficiaryName {
    if (beneficiary == null) return 'Unknown';
    return '${beneficiary!['firstName'] ?? ''} ${beneficiary!['lastName'] ?? ''}'.trim();
  }
}

// Beneficiary model
class BeneficiaryModel {
  final String id;
  final String firstName;
  final String lastName;
  final String country;
  final String currency;
  final String phone;
  final String relationship;
  final String payoutMethod;
  final Map<String, dynamic>? bankDetails;
  final Map<String, dynamic>? walletDetails;
  final int totalTransfers;

  const BeneficiaryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.currency,
    required this.phone,
    required this.relationship,
    required this.payoutMethod,
    this.bankDetails,
    this.walletDetails,
    required this.totalTransfers,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      country: json['country'] ?? '',
      currency: json['currency'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? 'family',
      payoutMethod: json['payoutMethod'] ?? 'bank_deposit',
      bankDetails: json['bankDetails'] as Map<String, dynamic>?,
      walletDetails: json['walletDetails'] as Map<String, dynamic>?,
      totalTransfers: json['totalTransfers'] ?? 0,
    );
  }
}
