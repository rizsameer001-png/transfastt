// lib/features/profile/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

// ── KYC doc replace tile ───────────────────────────────────────────────────
class _DocReplaceTile extends StatefulWidget {
  final String fieldName;
  final String label;
  final Map<String, dynamic>? existing; // { url, publicId }
  final void Function(String fieldName, Map<String, dynamic> newDoc) onUploaded;

  const _DocReplaceTile({
    required this.fieldName,
    required this.label,
    required this.existing,
    required this.onUploaded,
  });

  @override
  State<_DocReplaceTile> createState() => _DocReplaceTileState();
}

class _DocReplaceTileState extends State<_DocReplaceTile> {
  File?   _picked;
  bool    _uploading = false;

  Future<void> _pick() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, 'camera')),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, 'gallery')),
          ListTile(leading: const Icon(Icons.picture_as_pdf_rounded), title: const Text('PDF'),
            onTap: () => Navigator.pop(context, 'pdf')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (action == null || !mounted) return;

    File? file;
    if (action == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['pdf']);
      if (result?.files.single.path != null) file = File(result!.files.single.path!);
    } else {
      final img = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85, maxWidth: 1600,
      );
      if (img != null) file = File(img.path);
    }
    if (file == null) return;
    if (await file.length() > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 5 MB per file'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _picked = file);
  }

  Future<void> _upload() async {
    if (_picked == null) return;
    setState(() => _uploading = true);
    try {
      final res = await UserApiService().uploadKycDocument(widget.fieldName, _picked!.path);
      final doc = res['document'] as Map<String, dynamic>;
      widget.onUploaded(widget.fieldName, doc);
      setState(() => _picked = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.label} updated!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final url    = widget.existing?['url'] as String?;
    final isPDF  = url?.contains('/raw/') == true || url?.endsWith('.pdf') == true
        || _picked?.path.endsWith('.pdf') == true;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: SizedBox(
              height: 90, width: double.infinity,
              child: _picked != null
                  ? (isPDF
                      ? const Center(child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 36))
                      : Image.file(_picked!, fit: BoxFit.cover))
                  : (url != null
                      ? (isPDF
                          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 32),
                              Text('PDF', style: TextStyle(fontSize: 10, color: Colors.red)),
                            ]))
                          : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 1)),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppColors.textHint)))
                      : Center(child: Icon(Icons.upload_file_rounded,
                          color: AppColors.textHint.withOpacity(0.5), size: 28))),
            ),
          ),

          // Label + status chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: [
              Expanded(child: Text(widget.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (url != null && _picked == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('✓', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: _picked != null
                ? Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => setState(() => _picked = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Text('Cancel', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    )),
                    const SizedBox(width: 6),
                    Expanded(child: GestureDetector(
                      onTap: _uploading ? null : _upload,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8)),
                        child: _uploading
                            ? const Center(child: SizedBox(width: 12, height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)))
                            : const Text('Save', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    )),
                  ])
                : SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _pick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(url != null ? 'Replace' : 'Upload',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Screen ─────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;
  bool _docsExpanded    = false;
  bool _loadingDocs     = false;
  Map<String, dynamic>? _kycData;

  // Upload avatar
  Future<void> _pickAvatar() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 90, maxWidth: 800);
    if (img == null || !mounted) return;
    final file = File(img.path);
    if (await file.length() > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar must be under 2 MB'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _uploadingAvatar = true);
    try {
      final res = await UserApiService().uploadAvatar(img.path);
      final newUrl = res['avatar'] as String?;
      ref.read(authStateProvider.notifier).updateUser(
        ref.read(currentUserProvider)!.copyWith(avatar: newUrl));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _uploadingAvatar = false);
  }

  Future<void> _deleteAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      await UserApiService().deleteAvatar();
      ref.read(authStateProvider.notifier).updateUser(
        ref.read(currentUserProvider)!.copyWith(clearAvatar: true));
    } catch (_) {}
    setState(() => _uploadingAvatar = false);
  }

  Future<void> _loadKycDocs() async {
    if (_kycData != null) return;
    setState(() => _loadingDocs = true);
    try {
      final res = await KycApiService().getKycStatus();
      setState(() => _kycData = res['kyc'] as Map<String, dynamic>?);
    } catch (_) {}
    setState(() => _loadingDocs = false);
  }

  void _handleDocUploaded(String field, Map<String, dynamic> doc) {
    setState(() => _kycData = {...?_kycData, field: doc});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ── Avatar section ─────────────────────────────────────────────
          Stack(alignment: Alignment.bottomRight, children: [
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              child: _uploadingAvatar
                  ? Container(width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight),
                      child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                  : (user?.avatar != null
                      ? CachedNetworkImage(
                          imageUrl: user!.avatar!,
                          imageBuilder: (_, img) => Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              image: DecorationImage(image: img, fit: BoxFit.cover)),
                          ),
                          placeholder: (_, __) => Container(width: 90, height: 90,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryLight),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5))),
                          errorWidget: (_, __, ___) => _initialsAvatar(user),
                        )
                      : _initialsAvatar(user)),
            ),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
              ),
            ),
          ]),

          const SizedBox(height: 12),
          Text(user?.fullName ?? '', style: AppTextStyles.h3),
          Text(user?.email   ?? '', style: AppTextStyles.bodySm),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            StatusBadge(status: user?.kycStatus ?? 'pending'),
            if (user?.avatar != null) ...[ const SizedBox(width: 8),
              GestureDetector(
                onTap: _deleteAvatar,
                child: const Text('Remove photo',
                  style: TextStyle(fontSize: 11, color: AppColors.error, decoration: TextDecoration.underline)),
              ),
            ],
          ]),

          const SizedBox(height: 24),

          // Stats
          Row(children: [
            _statCard('Transfers', '${user?.totalTransfers ?? 0}'),
            const SizedBox(width: 12),
            _statCard('Total Sent', '\$${(user?.totalAmountSent ?? 0).toStringAsFixed(0)}'),
            const SizedBox(width: 12),
            _statCard('Country', user?.country ?? '-'),
          ]),

          const SizedBox(height: 20),

          // ── KYC Documents collapsible ──────────────────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.folder_open_rounded, color: AppColors.primary),
                title: const Text('KYC Documents', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Icon(_docsExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textHint),
                onTap: () {
                  setState(() => _docsExpanded = !_docsExpanded);
                  if (_docsExpanded) _loadKycDocs();
                },
              ),
              if (_docsExpanded) ...[ const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: _loadingDocs
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)))
                      : (_kycData == null && !_loadingDocs)
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No KYC record yet. Submit your KYC first.',
                                style: AppTextStyles.bodySm, textAlign: TextAlign.center))
                          : GridView.count(
                              crossAxisCount: 2, shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10, mainAxisSpacing: 10,
                              childAspectRatio: 0.9,
                              children: [
                                _DocReplaceTile(fieldName: 'idFrontImage',   label: 'ID Front',
                                  existing: _kycData?['idFrontImage']   as Map<String, dynamic>?, onUploaded: _handleDocUploaded),
                                _DocReplaceTile(fieldName: 'idBackImage',    label: 'ID Back',
                                  existing: _kycData?['idBackImage']    as Map<String, dynamic>?, onUploaded: _handleDocUploaded),
                                _DocReplaceTile(fieldName: 'selfieImage',    label: 'Selfie',
                                  existing: _kycData?['selfieImage']    as Map<String, dynamic>?, onUploaded: _handleDocUploaded),
                                _DocReplaceTile(fieldName: 'proofOfAddress', label: 'Proof of Address',
                                  existing: _kycData?['proofOfAddress'] as Map<String, dynamic>?, onUploaded: _handleDocUploaded),
                              ],
                            ),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 12),

          // ── Menu ──────────────────────────────────────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _menuItem(Icons.edit_rounded,         'Edit Profile',       () => _editProfile(context)),
              _divider(),
              _menuItem(Icons.lock_outline_rounded, 'Change Password',    () => _changePassword(context)),
              _divider(),
              _menuItem(Icons.shield_rounded,       'KYC Verification',   () => context.go('/kyc')),
              _divider(),
              _menuItem(Icons.receipt_long_rounded, 'Transaction History',() => context.go('/transactions')),
              _divider(),
              _menuItem(Icons.trending_up_rounded,  'Exchange Rates',     () => context.go('/rates')),
              if (user?.isAdmin ?? false) ...[
                _divider(),
                _menuItem(Icons.admin_panel_settings_rounded, 'Admin Panel', () => context.go('/admin')),
              ],
            ]),
          ),

          const SizedBox(height: 12),

          AppCard(
            padding: EdgeInsets.zero,
            child: _menuItem(Icons.logout_rounded, 'Sign Out',
              () => _confirmLogout(context), color: AppColors.error),
          ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _initialsAvatar(user) => Container(
    width: 90, height: 90,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
    child: Center(child: Text(user?.initials ?? 'U',
      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
  );

  Widget _statCard(String label, String value) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ]),
    ),
  );

  Widget _menuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) =>
    ListTile(
      leading: Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textHint),
      onTap: onTap,
    );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 0));

  void _editProfile(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProfileSheet(ref: ref));
  }

  void _changePassword(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePasswordSheet());
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('You will be signed out of your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Edit profile bottom sheet ──────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final WidgetRef ref;
  const _EditProfileSheet({required this.ref});
  @override State<_EditProfileSheet> createState() => _EditProfileSheetState();
}
class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _fn = TextEditingController(), _ln = TextEditingController(), _phone = TextEditingController();
  bool _saving = false;
  @override void initState() {
    super.initState();
    final user = widget.ref.read(currentUserProvider);
    _fn.text = user?.firstName ?? ''; _ln.text = user?.lastName ?? ''; _phone.text = user?.phone ?? '';
  }
  @override Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit Profile', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: AppTextField(label: 'First Name', controller: _fn)),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Last Name',  controller: _ln)),
          ]),
          const SizedBox(height: 12),
          AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          AppButton(label: 'Save Changes', isLoading: _saving, onPressed: () async {
            setState(() => _saving = true);
            try {
              await UserApiService().updateProfile({
                'firstName': _fn.text.trim(), 'lastName': _ln.text.trim(), 'phone': _phone.text.trim(),
              });
              widget.ref.read(authStateProvider.notifier).updateUser(
                widget.ref.read(currentUserProvider)!.copyWith(
                  firstName: _fn.text.trim(), lastName: _ln.text.trim(), phone: _phone.text.trim()));
              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
            }
            setState(() => _saving = false);
          }),
        ]),
      ),
    );
  }
}

// ── Change password bottom sheet ───────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}
class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _cur = TextEditingController(), _new = TextEditingController(), _confirm = TextEditingController();
  bool _saving = false;
  @override Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Change Password', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          AppTextField(label: 'Current Password', controller: _cur, obscureText: true),
          const SizedBox(height: 12),
          AppTextField(label: 'New Password', hint: 'Min. 8 characters', controller: _new, obscureText: true),
          const SizedBox(height: 12),
          AppTextField(label: 'Confirm New Password', controller: _confirm, obscureText: true),
          const SizedBox(height: 20),
          AppButton(label: 'Update Password', isLoading: _saving, onPressed: () async {
            if (_new.text != _confirm.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error));
              return;
            }
            if (_new.text.length < 8) return;
            setState(() => _saving = true);
            try {
              await AuthApiService().changePassword(_cur.text, _new.text);
              if (mounted) { Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password updated!'), backgroundColor: AppColors.success)); }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
            }
            setState(() => _saving = false);
          }),
        ]),
      ),
    );
  }
}
