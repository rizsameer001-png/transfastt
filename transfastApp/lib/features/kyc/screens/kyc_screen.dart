// lib/features/kyc/screens/kyc_screen.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

// ── Provider for KYC status ────────────────────────────────────────────────
final kycStatusProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final res = await KycApiService().getKycStatus();
  return res['kyc'] as Map<String, dynamic>?;
});

// ── File slot model ────────────────────────────────────────────────────────
class _FileSlot {
  final String fieldName;
  final String label;
  final bool required;
  File? file;
  String? cloudinaryUrl; // loaded from existing KYC doc

  _FileSlot({
    required this.fieldName,
    required this.label,
    this.required = false,
    this.file,
    this.cloudinaryUrl,
  });

  bool get hasFile => file != null;
  bool get hasCloud => cloudinaryUrl != null && cloudinaryUrl!.isNotEmpty;
  bool get hasAny => hasFile || hasCloud;
}

// ── Main screen ────────────────────────────────────────────────────────────
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});
  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dobCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String _sourceOfFunds = 'employment';
  String _idType = 'passport';
  bool _submitting = false;

  // Four document slots
  late final List<_FileSlot> _slots = [
    _FileSlot(fieldName: 'idFrontImage', label: 'ID Front', required: true),
    _FileSlot(fieldName: 'idBackImage', label: 'ID Back'),
    _FileSlot(fieldName: 'selfieImage', label: 'Selfie', required: true),
    _FileSlot(fieldName: 'proofOfAddress', label: 'Proof of Address'),
  ];

  @override
  void dispose() {
    for (final c in [
      _dobCtrl,
      _nationalityCtrl,
      _occupationCtrl,
      _idNumberCtrl,
      _streetCtrl,
      _cityCtrl,
      _stateCtrl,
      _postalCtrl,
      _countryCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Pre-fill form and existing Cloudinary URLs from a stored KYC document
  void _prefillFrom(Map<String, dynamic> kyc) {
    _dobCtrl.text = (kyc['dateOfBirth'] as String? ?? '').split('T').first;
    _nationalityCtrl.text = kyc['nationality'] as String? ?? '';
    _occupationCtrl.text = kyc['occupation'] as String? ?? '';
    _idNumberCtrl.text = kyc['idNumber'] as String? ?? '';
    _sourceOfFunds = kyc['sourceOfFunds'] as String? ?? 'employment';
    _idType = kyc['idType'] as String? ?? 'passport';

    final addr = kyc['address'] as Map<String, dynamic>? ?? {};
    _streetCtrl.text = addr['street'] as String? ?? '';
    _cityCtrl.text = addr['city'] as String? ?? '';
    _stateCtrl.text = addr['state'] as String? ?? '';
    _postalCtrl.text = addr['postalCode'] as String? ?? '';
    _countryCtrl.text = addr['country'] as String? ?? '';

    // Load Cloudinary URLs into file slots
    for (final slot in _slots) {
      final docField = kyc[slot.fieldName];
      if (docField is Map<String, dynamic>) {
        setState(() => slot.cloudinaryUrl = docField['url'] as String?);
      }
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(_FileSlot slot) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: const Text('Choose PDF'),
            onTap: () => Navigator.pop(context, 'pdf'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );

    if (action == null || !mounted) return;

    File? picked;

    if (action == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result?.files.single.path != null) {
        picked = File(result!.files.single.path!);
      }
    } else {
      final image = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image != null) picked = File(image.path);
    }

    if (picked != null) {
      // Validate size ≤ 5 MB
      final bytes = await picked.length();
      if (bytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File must be under 5 MB'),
                backgroundColor: AppColors.error),
          );
        }
        return;
      }
      setState(() {
        slot.file = picked;
        slot.cloudinaryUrl = null; // new file replaces old
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required files
    for (final slot in _slots.where((s) => s.required)) {
      if (!slot.hasAny) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${slot.label} is required'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final fields = <String, String>{
        'dateOfBirth': _dobCtrl.text.trim(),
        'nationality': _nationalityCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'sourceOfFunds': _sourceOfFunds,
        'idType': _idType,
        'idNumber': _idNumberCtrl.text.trim(),
        'address': jsonEncode({
          'street': _streetCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'postalCode': _postalCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
        }),
      };

      // Only attach slots where a new local file was picked
      final files = <String, String>{
        for (final slot in _slots)
          if (slot.file != null) slot.fieldName: slot.file!.path,
      };

      await KycApiService().submitKyc(fields, files: files);

      ref.read(authStateProvider.notifier).updateUser(
            ref.read(currentUserProvider)!.copyWith(kycStatus: 'submitted'),
          );
      ref.invalidate(kycStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('KYC submitted! Well review it within 1-2 business days.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ));
      }
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: kycAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (kyc) {
          // Pre-fill only once
          if (kyc != null && _dobCtrl.text.isEmpty) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _prefillFrom(kyc));
          }

          final status = kyc?['status'] as String? ??
              ref.watch(currentUserProvider)?.kycStatus ??
              'pending';

          final canSubmit = status == 'pending' || status == 'rejected';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StatusBanner(
                  status: status,
                  rejectedReason: kyc?['rejectedReason'] as String?),
              const SizedBox(height: 24),

              // Read-only doc view when submitted/approved
              if (!canSubmit && _slots.any((s) => s.hasCloud)) ...[
                Text('Submitted Documents', style: AppTextStyles.h4),
                const SizedBox(height: 12),
                _SubmittedDocsGrid(slots: _slots),
                const SizedBox(height: 24),
              ],

              if (!canSubmit) ...[
                if (status == 'under_review' || status == 'submitted')
                  const EmptyState(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Under Review',
                    subtitle:
                        'Your documents are being reviewed. This typically takes 1-2 business days.',
                  )
                else if (status == 'approved')
                  const EmptyState(
                    icon: Icons.verified_user_rounded,
                    title: 'KYC Approved!',
                    subtitle:
                        'Your identity is verified. You can now send money internationally.',
                  ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Personal info ──────────────────────────────────────
                        Text('Personal Information', style: AppTextStyles.h3),
                        const SizedBox(height: 16),

                        AppTextField(
                            label: 'Date of Birth *',
                            hint: 'YYYY-MM-DD',
                            controller: _dobCtrl,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        AppTextField(
                            label: 'Nationality *',
                            hint: 'e.g. American',
                            controller: _nationalityCtrl,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        AppTextField(
                            label: 'Occupation',
                            hint: 'Your job title',
                            controller: _occupationCtrl),
                        const SizedBox(height: 12),

                        _DropdownField(
                          label: 'Source of Funds *',
                          value: _sourceOfFunds,
                          items: const {
                            'employment': 'Employment',
                            'business': 'Business',
                            'savings': 'Savings',
                            'investment': 'Investment',
                            'inheritance': 'Inheritance',
                            'other': 'Other',
                          },
                          onChanged: (v) => setState(() => _sourceOfFunds = v),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // ── Identity document ──────────────────────────────────
                        Text('Identity Document', style: AppTextStyles.h3),
                        const SizedBox(height: 16),

                        _DropdownField(
                          label: 'ID Type *',
                          value: _idType,
                          items: const {
                            'passport': 'Passport',
                            'national_id': 'National ID',
                            'drivers_license': "Driver's License",
                            'residence_permit': 'Residence Permit',
                          },
                          onChanged: (v) => setState(() => _idType = v),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                            label: 'ID Number *',
                            hint: 'Document number',
                            controller: _idNumberCtrl,
                            validator: (v) => v!.isEmpty ? 'Required' : null),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // ── Document uploads ───────────────────────────────────
                        Text('Document Uploads', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text('JPG, PNG or PDF · Max 5 MB per file',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textHint)),
                        const SizedBox(height: 16),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: _slots
                              .map((slot) => _DocUploadTile(
                                    slot: slot,
                                    onTap: () => _pickImage(slot),
                                    onRemove: () => setState(() {
                                      slot.file = null;
                                      slot.cloudinaryUrl = null;
                                    }),
                                  ))
                              .toList(),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // ── Address ────────────────────────────────────────────
                        Text('Residential Address', style: AppTextStyles.h3),
                        const SizedBox(height: 16),

                        AppTextField(
                            label: 'Street Address *',
                            hint: '123 Main Street',
                            controller: _streetCtrl,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: AppTextField(
                                  label: 'City *',
                                  hint: 'New York',
                                  controller: _cityCtrl,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: AppTextField(
                                  label: 'State',
                                  hint: 'NY',
                                  controller: _stateCtrl)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: AppTextField(
                                  label: 'Postal Code',
                                  hint: '10001',
                                  controller: _postalCtrl)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: AppTextField(
                                  label: 'Country *',
                                  hint: 'United States',
                                  controller: _countryCtrl,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null)),
                        ]),

                        const SizedBox(height: 32),
                        AppButton(
                          label: _submitting
                              ? 'Uploading & Submitting...'
                              : 'Submit KYC Documents',
                          icon: Icons.shield_rounded,
                          onPressed: _submit,
                          isLoading: _submitting,
                        ),
                        const SizedBox(height: 20),
                      ]),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

// ── Status banner ──────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  final String? rejectedReason;
  const _StatusBanner({required this.status, this.rejectedReason});

  @override
  Widget build(BuildContext context) {
    final configs = <String, Map<String, dynamic>>{
      'pending': {
        'color': AppColors.warning,
        'icon': Icons.shield_outlined,
        'title': 'Verification Required',
        'msg': 'Submit your documents to unlock international transfers.'
      },
      'submitted': {
        'color': AppColors.info,
        'icon': Icons.access_time_rounded,
        'title': 'Submitted',
        'msg': 'Your documents are under review. Usually 1-2 business days.'
      },
      'under_review': {
        'color': AppColors.info,
        'icon': Icons.search_rounded,
        'title': 'Under Review',
        'msg': 'We\'re reviewing your documents. Usually 1-2 business days.'
      },
      'approved': {
        'color': AppColors.success,
        'icon': Icons.check_circle_rounded,
        'title': 'KYC Approved',
        'msg': 'Your identity is verified. You can now send money!'
      },
      'rejected': {
        'color': AppColors.error,
        'icon': Icons.cancel_rounded,
        'title': 'KYC Rejected',
        'msg': rejectedReason ?? 'Please fix the issues and resubmit.'
      },
    };
    final c = configs[status] ?? configs['pending']!;
    final color = c['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(c['icon'] as IconData, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['title'] as String,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          const SizedBox(height: 2),
          Text(c['msg'] as String, style: AppTextStyles.bodySm),
        ])),
      ]),
    );
  }
}

// ── Document upload tile ───────────────────────────────────────────────────
class _DocUploadTile extends StatelessWidget {
  final _FileSlot slot;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _DocUploadTile(
      {required this.slot, required this.onTap, required this.onRemove});

  bool get _isPDF =>
      slot.cloudinaryUrl?.contains('/raw/') == true ||
      slot.cloudinaryUrl?.endsWith('.pdf') == true ||
      slot.file?.path.endsWith('.pdf') == true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slot.hasAny ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: slot.hasAny
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
            width: slot.hasAny ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          color: slot.hasAny
              ? AppColors.primary.withOpacity(0.04)
              : AppColors.background,
        ),
        child: Stack(children: [
          // Content
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (slot.file != null && !_isPDF)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(slot.file!,
                    height: 80, width: double.infinity, fit: BoxFit.cover),
              )
            else if (slot.cloudinaryUrl != null && !_isPDF)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(slot.cloudinaryUrl!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textHint,
                        size: 32)),
              )
            else if (_isPDF)
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.red, size: 36)
            else ...[
              Icon(Icons.upload_file_rounded,
                  color: slot.required ? AppColors.primary : AppColors.textHint,
                  size: 28),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(slot.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: slot.required
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    textAlign: TextAlign.center),
              ),
              if (slot.required)
                const Text('Required',
                    style: TextStyle(fontSize: 10, color: Colors.red)),
            ],
            if (slot.hasAny) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(slot.label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ]),

          // Remove button (top-right)
          if (slot.hasAny)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),

          // Replace button (bottom when has file)
          if (slot.hasAny)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Replace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),

          // Checkmark overlay
          if (slot.hasAny)
            const Positioned(
              top: 6,
              left: 6,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.success,
                child: Icon(Icons.check, color: Colors.white, size: 13),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Submitted docs grid (read-only) ───────────────────────────────────────
class _SubmittedDocsGrid extends StatelessWidget {
  final List<_FileSlot> slots;
  const _SubmittedDocsGrid({required this.slots});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: slots.map((slot) {
        final url = slot.cloudinaryUrl;
        final isPDF =
            url?.contains('/raw/') == true || url?.endsWith('.pdf') == true;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
                color: url != null
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(fit: StackFit.expand, children: [
              if (url != null && !isPDF)
                Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.textHint))
              else if (url != null && isPDF)
                const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.red, size: 36),
                      SizedBox(height: 4),
                      Text('PDF',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w600)),
                    ])
              else
                const Center(
                    child: Icon(Icons.help_outline_rounded,
                        color: AppColors.textHint, size: 28)),

              // Label bar at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  color: Colors.black54,
                  child: Text(slot.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),

              if (url != null)
                const Positioned(
                    top: 6,
                    right: 6,
                    child: CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.success,
                        child:
                            Icon(Icons.check, color: Colors.white, size: 11))),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Reusable dropdown ──────────────────────────────────────────────────────
class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final void Function(String) onChanged;
  const _DropdownField(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.label),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ]);
  }
}
