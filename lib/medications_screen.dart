import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});
  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<dynamic> _meds = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMedications();
      if (mounted) setState(() { _meds = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final taken = _meds.where((m) => (m['taken'] as List? ?? []).any((t) => t == true)).length;

    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(title: const Text('Medications')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMed,
        backgroundColor: HMColors.accent,
        foregroundColor: const Color(0xFF001a1a),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Medication', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load, color: HMColors.accent, backgroundColor: HMColors.surface,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
            : _meds.isEmpty
                ? const HMEmptyState(emoji: '💊', title: 'No medications',
                    subtitle: 'Add your medications to track your daily doses')
                : CustomScrollView(slivers: [
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(child: HMStatCard(
                          label: 'Taken Today', value: '$taken/${_meds.length}',
                          unit: 'doses', valueColor: HMColors.success,
                          progress: _meds.isNotEmpty ? taken / _meds.length : 0,
                          progressColor: HMColors.success,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: HMStatCard(
                          label: 'Remaining',
                          value: '${_meds.length - taken}',
                          unit: 'doses left',
                          valueColor: taken == _meds.length ? HMColors.success : HMColors.warning,
                          badge: taken == _meds.length ? 'All done!' : null,
                          badgeColor: HMColors.success,
                        )),
                      ]),
                    )),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final med = _meds[i] as Map<String, dynamic>;
                          final times = (med['taken'] as List? ?? []);
                          Color medColor;
                          try {
                            medColor = Color(int.parse((med['color'] ?? '#00d4c8').replaceFirst('#', '0xFF')));
                          } catch (_) { medColor = HMColors.accent; }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: HMColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: HMColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: medColor, width: 2),
                                ),
                                child: Center(child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: medColor.withOpacity(0.2)),
                                  child: Center(child: Text('💊', style: const TextStyle(fontSize: 12))),
                                )),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(med['name'] ?? '', style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
                                Text('${med['dose'] ?? ''} · ${med['frequency'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: HMColors.text3)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 6, children: List.generate(
                                  (med['times'] as List? ?? []).length,
                                  (j) {
                                    final isTaken = j < times.length && times[j] == true;
                                    return GestureDetector(
                                      onTap: () => _toggleDose(med['id'], j, !isTaken),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isTaken ? HMColors.success.withOpacity(0.1) : HMColors.warning.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isTaken ? HMColors.success.withOpacity(0.3) : HMColors.warning.withOpacity(0.25)),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(isTaken ? Icons.check_circle_rounded : Icons.access_time_rounded,
                                              size: 12, color: isTaken ? HMColors.success : HMColors.warning),
                                          const SizedBox(width: 4),
                                          Text((med['times'] as List)[j] ?? '', style: TextStyle(
                                              fontSize: 11, color: isTaken ? HMColors.success : HMColors.warning,
                                              fontWeight: FontWeight.w500)),
                                        ]),
                                      ),
                                    );
                                  },
                                )),
                              ])),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, size: 18, color: HMColors.text3),
                                onPressed: () => _deleteMed(med['id']),
                              ),
                            ]),
                          );
                        },
                        childCount: _meds.length,
                      )),
                    ),
                  ]),
      ),
    );
  }

  Future<void> _toggleDose(int medId, int doseIndex, bool taken) async {
    try {
      await ApiService.logMedication({'med_id': medId, 'dose_index': doseIndex, 'taken': taken});
      _load();
    } catch (e) { if (mounted) showHMToast(context, e.toString(), isError: true); }
  }

  Future<void> _deleteMed(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HMColors.surface,
        title: const Text('Delete Medication?', style: TextStyle(color: HMColors.text)),
        content: const Text('This will remove it from your schedule.',
            style: TextStyle(color: HMColors.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: HMColors.text3))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: HMColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService.deleteMedication(id);
        _load();
      } catch (e) { if (mounted) showHMToast(context, e.toString(), isError: true); }
    }
  }

  void _showAddMed() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMedSheet(onSaved: _load),
    );
  }
}

class _AddMedSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddMedSheet({required this.onSaved});
  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _freq = 'Daily';
  List<String> _times = ['09:00'];
  bool _loading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addMedication({
        'name': _nameCtrl.text.trim(),
        'dose': _doseCtrl.text.trim(),
        'frequency': _freq,
        'times': _times,
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      if (mounted) showHMToast(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: HMColors.text3, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Add Medication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          HMTextField(label: 'Medication Name', hint: 'e.g. Metformin', controller: _nameCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Dose', hint: 'e.g. 500mg', controller: _doseCtrl),
          const SizedBox(height: 14),
          const Text('FREQUENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: HMColors.text3, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['Daily', 'Twice daily', 'Three times', 'Weekly'].map((f) =>
            ChoiceChip(
              label: Text(f), selected: _freq == f,
              onSelected: (_) => setState(() {
                _freq = f;
                if (f == 'Twice daily') _times = ['08:00', '20:00'];
                else if (f == 'Three times') _times = ['08:00', '14:00', '20:00'];
                else _times = ['09:00'];
              }),
              selectedColor: HMColors.accent.withOpacity(0.15),
              backgroundColor: HMColors.bg3,
              labelStyle: TextStyle(color: _freq == f ? HMColors.accent : HMColors.text2, fontSize: 12),
              side: BorderSide(color: _freq == f ? HMColors.accent : HMColors.border2),
            )
          ).toList()),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Add Medication', onTap: _save, loading: _loading)),
        ]),
      ),
    );
  }
}
