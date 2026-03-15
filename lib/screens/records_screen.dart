import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRecords();
      if (mounted) setState(() { _records = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    await _uploadFile(File(picked.path));
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _uploading = true);
    try {
      // Use the food photo endpoint for images — reuse pattern
      showHMToast(context, 'Uploading record...');
      // Upload via multipart
      await ApiService.uploadRecord(file);
      if (mounted) {
        showHMToast(context, 'Record uploaded & analyzed ✓');
        _load();
      }
    } catch (e) {
      if (mounted) showHMToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: HMColors.text3, borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Upload Health Record', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w600, color: HMColors.text)),
        ),
        _UploadOption(icon: Icons.camera_alt_rounded, label: 'Take Photo',
            subtitle: 'Capture a prescription or report',
            onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.camera); }),
        _UploadOption(icon: Icons.photo_library_rounded, label: 'Choose from Gallery',
            subtitle: 'Select an existing image',
            onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.gallery); }),
        const SizedBox(height: 16),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(title: const Text('Health Records')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _showUploadOptions,
        backgroundColor: HMColors.accent,
        foregroundColor: const Color(0xFF001a1a),
        icon: _uploading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF001a1a)))
            : const Icon(Icons.upload_rounded),
        label: Text(_uploading ? 'Uploading...' : 'Upload Record',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load, color: HMColors.accent, backgroundColor: HMColors.surface,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
            : _records.isEmpty
                ? const HMEmptyState(emoji: '📋', title: 'No records yet',
                    subtitle: 'Upload prescriptions, lab reports, or X-rays.\nAI will analyze them automatically.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _records.length,
                    itemBuilder: (_, i) {
                      final r = _records[i] as Map<String, dynamic>;
                      return _RecordCard(record: r, onDelete: _load);
                    },
                  ),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _UploadOption({required this.icon, required this.label,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: HMColors.accent2.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HMColors.accent2.withOpacity(0.2)),
        ),
        child: Icon(icon, color: HMColors.accent2, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: HMColors.text3)),
      onTap: onTap,
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onDelete;
  const _RecordCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ext = (record['file_type'] ?? 'file').toLowerCase();
    final isImage = ['png', 'jpg', 'jpeg'].contains(ext);
    String dateStr = '';
    try {
      dateStr = DateFormat('MMM d, yyyy · h:mm a')
          .format(DateTime.parse(record['uploaded_at']));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: HMColors.accent2.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HMColors.accent2.withOpacity(0.2)),
              ),
              child: Center(child: Text(isImage ? '🖼️' : '📄',
                  style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record['original_name'] ?? 'Record',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: HMColors.text),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: HMColors.text3)),
            ])),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: HMColors.text3, size: 18),
              onPressed: () async {
                await ApiService.deleteRecord(record['id']);
                onDelete();
              },
            ),
          ]),
        ),
        // AI Analysis
        if ((record['analysis'] ?? '').toString().length > 20)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HMColors.bg3,
              borderRadius: BorderRadius.circular(10),
              border: const Border(left: BorderSide(color: HMColors.accent2, width: 2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, size: 12, color: HMColors.accent2),
                SizedBox(width: 4),
                Text('AI Analysis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: HMColors.accent2)),
              ]),
              const SizedBox(height: 6),
              Text(record['analysis'], style: const TextStyle(fontSize: 13, color: HMColors.text2, height: 1.5)),
            ]),
          ),
      ]),
    );
  }
}
