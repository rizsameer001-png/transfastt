// lib/features/auth/models/user_model.dart
import 'dart:convert';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String country;
  final String role;
  final String kycStatus;
  final bool isEmailVerified;
  final bool isActive;
  final bool isSuspended;
  final int totalTransfers;
  final double totalAmountSent;
  final String? lastLogin;
  final String currency;
  final String? avatar;        // Cloudinary URL
  final String? avatarPublicId;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.country,
    required this.role,
    required this.kycStatus,
    required this.isEmailVerified,
    required this.isActive,
    required this.isSuspended,
    required this.totalTransfers,
    required this.totalAmountSent,
    this.lastLogin,
    this.currency = 'USD',
    this.avatar,
    this.avatarPublicId,
  });

  String get fullName  => '$firstName $lastName';
  String get initials  => '${firstName[0]}${lastName[0]}'.toUpperCase();
  bool get isAdmin     => ['admin', 'compliance', 'support'].contains(role);
  bool get isKycApproved => kycStatus == 'approved';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:              json['_id'] ?? json['id'] ?? '',
      firstName:       json['firstName'] ?? '',
      lastName:        json['lastName']  ?? '',
      email:           json['email']     ?? '',
      phone:           json['phone']     ?? '',
      country:         json['country']   ?? '',
      role:            json['role']      ?? 'user',
      kycStatus:       json['kycStatus'] ?? 'pending',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive:        json['isActive']        ?? true,
      isSuspended:     json['isSuspended']     ?? false,
      totalTransfers:  json['totalTransfers']  ?? 0,
      totalAmountSent: (json['totalAmountSent'] ?? 0).toDouble(),
      lastLogin:       json['lastLogin'],
      currency:        json['currency'] ?? 'USD',
      avatar:          json['avatar'],
      avatarPublicId:  json['avatarPublicId'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':            id,
    'firstName':      firstName,
    'lastName':       lastName,
    'email':          email,
    'phone':          phone,
    'country':        country,
    'role':           role,
    'kycStatus':      kycStatus,
    'isEmailVerified':isEmailVerified,
    'isActive':       isActive,
    'isSuspended':    isSuspended,
    'totalTransfers': totalTransfers,
    'totalAmountSent':totalAmountSent,
    'lastLogin':      lastLogin,
    'currency':       currency,
    if (avatar != null)         'avatar':        avatar,
    if (avatarPublicId != null) 'avatarPublicId':avatarPublicId,
  };

  String toJsonString() => json.encode(toJson());
  factory UserModel.fromJsonString(String s) => UserModel.fromJson(json.decode(s));

  UserModel copyWith({
    String? firstName, String? lastName, String? phone,
    String? kycStatus, bool? isEmailVerified,
    int? totalTransfers, double? totalAmountSent,
    String? avatar, String? avatarPublicId,
    bool clearAvatar = false,
  }) {
    return UserModel(
      id: id, email: email, country: country, role: role,
      isActive: isActive, isSuspended: isSuspended, lastLogin: lastLogin, currency: currency,
      firstName:       firstName       ?? this.firstName,
      lastName:        lastName        ?? this.lastName,
      phone:           phone           ?? this.phone,
      kycStatus:       kycStatus       ?? this.kycStatus,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      totalTransfers:  totalTransfers  ?? this.totalTransfers,
      totalAmountSent: totalAmountSent ?? this.totalAmountSent,
      avatar:          clearAvatar ? null : (avatar ?? this.avatar),
      avatarPublicId:  clearAvatar ? null : (avatarPublicId ?? this.avatarPublicId),
    );
  }
}
