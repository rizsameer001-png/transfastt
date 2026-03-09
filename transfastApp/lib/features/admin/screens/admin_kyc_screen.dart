// lib/features/admin/screens/admin_kyc_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

// ── Admin KYC Screen ───────────────────────────────────────────────────────
class AdminKycScreen extends ConsumerStatefulWidget {
  const AdminKycScreen({super.key});
  @override ConsumerState<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends ConsumerState<AdminKycScreen> {
  List<Map<String, dynamic>> _kycList = [];
  bool   _loading      = true;
  String _statusFilter = 'under_review';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService().getKycList(status: _statusFilter);
      setState(() => _kycList = (res['kycList'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Review'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: ['under_review', 'approved', 'rejected', ''].map((s) {
              final label  = s.isEmpty ? 'All' : s.replaceAll('_', ' ');
              final active = s == _statusFilter;
              return GestureDetector(
                onTap: () { setState(() => _statusFilter = s); _load(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.primary : AppColors.border)),
                  child: Text(label, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList()),
          ),
        ),
      ),
      body: _loading
          ? const AppLoader()
          : _kycList.isEmpty
              ? const EmptyState(icon: Icons.shield_outlined, title: 'No KYC submissions')
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _kycList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _KycCard(
                      kyc: _kycList[i],
                      onReview: _load,
                    ),
                  ),
                ),
    );
  }
}

// ── KYC list card ──────────────────────────────────────────────────────────
class _KycCard extends StatelessWidget {
  final Map<String, dynamic> kyc;
  final VoidCallback onReview;
  const _KycCard({required this.kyc, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final user       = kyc['user'] as Map<String, dynamic>?;
    final isPending  = kyc['status'] == 'under_review';
    final docCount   = ['idFrontImage','idBackImage','selfieImage','proofOfAddress']
        .where((k) => (kyc[k] as Map?)?.containsKey('url') == true).length;
    final adminCount = (kyc['adminDocuments'] as List?)?.length ?? 0;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18, backgroundColor: AppColors.primaryLight,
            child: Text('${user?['firstName']?[0] ?? ''}${user?['lastName']?[0] ?? ''}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${user?['firstName']} ${user?['lastName']}', style: AppTextStyles.label),
            Text(user?['email'] ?? '', style: AppTextStyles.caption),
          ])),
          StatusBadge(status: kyc['status'] ?? ''),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Text('ID: ${(kyc['idType'] ?? '').toString().replaceAll('_', ' ')}', style: AppTextStyles.caption),
          const SizedBox(width: 12),
          Text('Funds: ${kyc['sourceOfFunds'] ?? ''}', style: AppTextStyles.caption),
          const Spacer(),
          // Doc count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: docCount == 4 ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6)),
            child: Text('$docCount/4 docs',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                color: docCount == 4 ? AppColors.success : AppColors.warning)),
          ),
          if (adminCount > 0) ...[ const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('+$adminCount admin', style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.info)),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.visibility_rounded, size: 14),
            label: const Text('Review', style: TextStyle(fontSize: 12)),
            onPressed: () => _showDetail(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 12)),
          )),
          if (isPending) ...[ const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('Approve', style: TextStyle(fontSize: 12)),
              onPressed: () async {
                await AdminApiService().reviewKyc(kyc['_id'], 'approve');
                onReview();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success),
                minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 12)),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Reject', style: TextStyle(fontSize: 12)),
              onPressed: () => _showRejectDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 12)),
            )),
          ],
        ]),
      ]),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject KYC'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await AdminApiService().reviewKyc(kyc['_id'], 'reject', reason: ctrl.text.trim());
              onReview();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _KycDetailSheet(kyc: kyc, onAction: onReview),
    );
  }
}

// ── KYC detail bottom sheet ────────────────────────────────────────────────
class _KycDetailSheet extends StatefulWidget {
  final Map<String, dynamic> kyc;
  final VoidCallback onAction;
  const _KycDetailSheet({required this.kyc, required this.onAction});
  @override State<_KycDetailSheet> createState() => _KycDetailSheetState();
}

class _KycDetailSheetState extends State<_KycDetailSheet> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Map<String, dynamic> _kyc;
  bool _replacingDoc = false;

  @override void initState() {
    super.initState();
    _kyc  = Map<String, dynamic>.from(widget.kyc);
    _tabs = TabController(length: 2, vsync: this);
  }
  @override void dispose() { _tabs.dispose(); super.dispose(); }

  // Pick file helper
  Future<File?> _pickFile() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Camera'),
          onTap: () => Navigator.pop(context, 'camera')),
        ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Gallery'),
          onTap: () => Navigator.pop(context, 'gallery')),
        ListTile(leading: const Icon(Icons.picture_as_pdf_rounded), title: const Text('PDF'),
          onTap: () => Navigator.pop(context, 'pdf')),
        const SizedBox(height: 8),
      ])),
    );
    if (action == null) return null;
    if (action == 'pdf') {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (r?.files.single.path != null) return File(r!.files.single.path!);
    } else {
      final img = await ImagePicker().pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85, maxWidth: 1600);
      if (img != null) return File(img.path);
    }
    return null;
  }

  // Admin replace a user doc field
  Future<void> _replaceDoc(String field) async {
    final file = await _pickFile();
    if (file == null) return;
    setState(() => _replacingDoc = true);
    try {
      final res = await AdminApiService().replaceKycDoc(_kyc['_id'], field, file.path);
      setState(() => _kyc = res['kyc'] as Map<String, dynamic>);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$field replaced'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _replacingDoc = false);
  }

  // Admin upload supplementary doc
  Future<void> _uploadAdminDoc() async {
    String label = '', note = '';
    await showDialog(
      context: context,
      builder: (_) {
        final lCtrl = TextEditingController(), nCtrl = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Document'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: lCtrl,
              decoration: const InputDecoration(labelText: 'Label *', hintText: 'e.g. Bank Statement')),
            const SizedBox(height: 12),
            TextField(controller: nCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () {
              label = lCtrl.text.trim(); note = nCtrl.text.trim();
              Navigator.pop(context);
            }, child: const Text('Next: Pick File')),
          ],
        );
      },
    );
    if (label.isEmpty) return;

    final file = await _pickFile();
    if (file == null) return;
    setState(() => _replacingDoc = true);
    try {
      final res = await AdminApiService().uploadKycDoc(_kyc['_id'], file.path, label, note: note.isEmpty ? null : note);
      final updatedDocs = (res['kyc'] as Map<String, dynamic>)['adminDocuments'] as List;
      setState(() => _kyc = {..._kyc, 'adminDocuments': updatedDocs});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _replacingDoc = false);
  }

  // Admin delete supplementary doc
  Future<void> _deleteAdminDoc(String docId) async {
    setState(() => _replacingDoc = true);
    try {
      await AdminApiService().deleteKycDoc(_kyc['_id'], docId);
      final docs = (_kyc['adminDocuments'] as List)
          .where((d) => (d as Map)['_id'] != docId).toList();
      setState(() => _kyc = {..._kyc, 'adminDocuments': docs});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _replacingDoc = false);
  }

  @override
  Widget build(BuildContext context) {
    final user     = _kyc['user'] as Map<String, dynamic>?;
    final isPending = _kyc['status'] == 'under_review';
    final adminDocs = (_kyc['adminDocuments'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final docFields = [
      {'key': 'idFrontImage',   'label': 'ID Front'},
      {'key': 'idBackImage',    'label': 'ID Back'},
      {'key': 'selfieImage',    'label': 'Selfie'},
      {'key': 'proofOfAddress', 'label': 'Proof of Address'},
    ];

    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.92, maxChildSize: 0.95, minChildSize: 0.5,
      builder: (_, scrollCtrl) => Column(children: [
        // Handle bar
        Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),

        // Header
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${user?['firstName']} ${user?['lastName']}', style: AppTextStyles.h3),
              Text(user?['email'] ?? '', style: AppTextStyles.caption),
            ])),
            StatusBadge(status: _kyc['status'] ?? ''),
          ])),

        const SizedBox(height: 12),

        // Tabs
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Documents (${docFields.where((d) => (_kyc[d['key']] as Map?)?.containsKey('url') == true).length}/4)'),
            Tab(text: 'Admin Docs${adminDocs.isNotEmpty ? " (${adminDocs.length})" : ""}'),
          ],
        ),

        Expanded(
          child: TabBarView(controller: _tabs, children: [

            // ── Tab 1: User docs ──────────────────────────────────────────
            SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95,
                  children: docFields.map((d) {
                    final key  = d['key']!;
                    final label= d['label']!;
                    final doc  = _kyc[key] as Map<String, dynamic>?;
                    final url  = doc?['url'] as String?;
                    final isPDF= url?.contains('/raw/') == true || url?.endsWith('.pdf') == true;
                    return Stack(children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: url != null ? AppColors.primary.withOpacity(0.4) : AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                          color: url != null ? AppColors.primary.withOpacity(0.03) : AppColors.background,
                        ),
                        child: Column(children: [
                          Expanded(child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                            child: url == null
                                ? Center(child: Icon(Icons.upload_file_rounded,
                                    color: AppColors.textHint.withOpacity(0.4), size: 32))
                                : isPDF
                                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 36),
                                        Text('PDF', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
                                      ]))
                                    : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 1)),
                                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppColors.textHint)),
                          )),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(children: [
                              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _replacingDoc ? null : () => _replaceDoc(key),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(6)),
                                  child: _replacingDoc
                                      ? const Center(child: SizedBox(width: 12, height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary)))
                                      : Text(url != null ? 'Replace' : 'Upload',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                      if (url != null)
                        const Positioned(top: 6, left: 6,
                          child: CircleAvatar(radius: 9, backgroundColor: AppColors.success,
                            child: Icon(Icons.check, size: 11, color: Colors.white))),
                    ]);
                  }).toList(),
                ),

                // Info
                const SizedBox(height: 16),
                ...[ 'Nationality', 'ID Type', 'ID Number', 'Source of Funds' ].asMap().entries.map((e) {
                  final vals = [
                    _kyc['nationality'] ?? '-',
                    (_kyc['idType'] ?? '-').toString().replaceAll('_', ' '),
                    _kyc['idNumber'] ?? '-',
                    _kyc['sourceOfFunds'] ?? '-',
                  ];
                  return InfoRow(label: e.value, value: vals[e.key], isLast: e.key == 3);
                }),

                // Rejection reason
                if (_kyc['rejectedReason'] != null) ...[ const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Rejection Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                      const SizedBox(height: 4),
                      Text(_kyc['rejectedReason'], style: AppTextStyles.bodySm),
                    ]),
                  ),
                ],
              ]),
            ),

            // ── Tab 2: Admin docs ─────────────────────────────────────────
            SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Upload button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _replacingDoc
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload Document'),
                    onPressed: _replacingDoc ? null : _uploadAdminDoc,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                  ),
                ),
                const SizedBox(height: 16),

                if (adminDocs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(icon: Icons.folder_open_rounded, title: 'No admin documents',
                      subtitle: 'Upload supplementary docs such as bank statements, extra IDs, etc.'),
                  )
                else
                  ...adminDocs.map((doc) {
                    final docUrl  = doc['url'] as String?;
                    final isPdf   = docUrl?.contains('/raw/') == true || docUrl?.endsWith('.pdf') == true;
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(width: 52, height: 52,
                            child: docUrl == null
                                ? const Icon(Icons.description_rounded, color: AppColors.textHint)
                                : isPdf
                                    ? Container(color: Colors.red.withOpacity(0.1),
                                        child: const Center(child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28)))
                                    : CachedNetworkImage(imageUrl: docUrl, fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: AppColors.textHint)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(doc['label'] ?? 'Document', style: AppTextStyles.label),
                          if ((doc['note'] as String?)?.isNotEmpty == true)
                            Text(doc['note'], style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                            doc['uploadedAt'] != null
                                ? DateTime.tryParse(doc['uploadedAt'])?.toLocal().toString().substring(0,10) ?? ''
                                : '',
                            style: AppTextStyles.caption),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => _deleteAdminDoc(doc['_id']),
                        ),
                      ]),
                    );
                  }),
              ]),
            ),
          ]),
        ),

        // Action buttons for under_review
        if (isPending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AdminApiService().reviewKyc(_kyc['_id'], 'approve');
                  widget.onAction();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success)),
                child: const Text('Approve'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final ctrl = TextEditingController();
                  showDialog(context: context, builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Rejection Reason'),
                    content: TextField(controller: ctrl, maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Enter reason...')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          if (ctrl.text.trim().isEmpty) return;
                          Navigator.pop(context); Navigator.pop(context);
                          await AdminApiService().reviewKyc(_kyc['_id'], 'reject', reason: ctrl.text.trim());
                          widget.onAction();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        child: const Text('Reject'),
                      ),
                    ],
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Reject'),
              )),
            ]),
          ),

        const SizedBox(height: 8),
      ]),
    );
  }
}
