import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class CycleScreen extends StatefulWidget {
  const CycleScreen({super.key});
  @override
  State<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends State<CycleScreen> {
  List<dynamic> _cycles = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getCycle();
      if (mounted) setState(() { _cycles = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Map<String, dynamic>? get _latest => _cycles.isNotEmpty ? _cycles.first as Map<String, dynamic> : null;

  int? get _avgCycle {
    if (_cycles.length < 2) return null;
    final lengths = _cycles
        .where((c) => c['cycle_length'] != null)
        .map((c) => c['cycle_length'] as int)
        .toList();
    if (lengths.isEmpty) return null;
    return lengths.reduce((a, b) => a + b) ~/ lengths.length;
  }

  DateTime? get _nextPredicted {
    if (_latest == null) return null;
    try {
      final start = DateTime.parse(_latest!['start_date']);
      final len = _avgCycle ?? 28;
      return start.add(Duration(days: len));
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextPredicted;
    final daysUntil = next != null ? next.difference(DateTime.now()).inDays : null;

    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(title: const Text('Cycle Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLog,
        backgroundColor: const Color(0xFFff6eb4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Period', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load, color: const Color(0xFFff6eb4), backgroundColor: HMColors.surface,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFff6eb4)))
            : CustomScrollView(slivers: [
                if (_latest != null)
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      // Prediction card
                      if (next != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x22ff6eb4), Color(0x22ff4d6d)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x44ff6eb4)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0x22ff6eb4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x44ff6eb4)),
                              ),
                              child: Center(child: Text(
                                daysUntil != null && daysUntil <= 0 ? '🔴' : '🌸',
                                style: const TextStyle(fontSize: 26),
                              )),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Next Period', style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFff6eb4))),
                              const SizedBox(height: 4),
                              Text(DateFormat('EEEE, MMM d').format(next),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: HMColors.text)),
                              const SizedBox(height: 2),
                              Text(
                                daysUntil == null ? ''
                                    : daysUntil <= 0 ? 'Period may have started'
                                    : daysUntil == 1 ? 'Tomorrow'
                                    : 'In $daysUntil days',
                                style: TextStyle(fontSize: 13,
                                    color: daysUntil != null && daysUntil <= 3 ? HMColors.warning : HMColors.text2),
                              ),
                            ])),
                          ]),
                        ),
                      const SizedBox(height: 12),
                      // Stats row
                      Row(children: [
                        Expanded(child: HMStatCard(
                          label: 'Avg Cycle Length',
                          value: '${_avgCycle ?? 28}',
                          unit: 'days', valueColor: const Color(0xFFff6eb4),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: HMStatCard(
                          label: 'Cycles Tracked',
                          value: '${_cycles.length}',
                          unit: 'total', valueColor: HMColors.accent3,
                        )),
                      ]),
                    ]),
                  )),

                if (_cycles.isEmpty)
                  const SliverFillRemaining(child: HMEmptyState(
                    emoji: '🌸', title: 'No cycle data yet',
                    subtitle: 'Start tracking your menstrual cycle\nfor period predictions and health insights',
                  ))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final c = _cycles[i] as Map<String, dynamic>;
                        String start = '', end = '';
                        try { start = DateFormat('MMM d, yyyy').format(DateTime.parse(c['start_date'])); } catch (_) {}
                        try { end = DateFormat('MMM d, yyyy').format(DateTime.parse(c['end_date'] ?? '')); } catch (_) {}
                        final symptoms = (c['symptoms'] ?? '[]').toString()
                            .replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HMColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: const Border(left: BorderSide(color: Color(0xFFff6eb4), width: 3)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Text('🌸', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('$start — $end',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HMColors.text)),
                                if (c['cycle_length'] != null)
                                  Text('${c['cycle_length']} day cycle',
                                      style: const TextStyle(fontSize: 12, color: HMColors.text3)),
                              ])),
                              if (c['flow_intensity'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0x22ff6eb4),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0x44ff6eb4)),
                                  ),
                                  child: Text(c['flow_intensity'], style: const TextStyle(
                                      fontSize: 11, color: Color(0xFFff6eb4), fontWeight: FontWeight.w500)),
                                ),
                            ]),
                            if (symptoms.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Symptoms: $symptoms',
                                  style: const TextStyle(fontSize: 12, color: HMColors.text2)),
                            ],
                            if ((c['notes'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(c['notes'], style: const TextStyle(fontSize: 12, color: HMColors.text3)),
                            ],
                          ]),
                        );
                      },
                      childCount: _cycles.length,
                    )),
                  ),
              ]),
      ),
    );
  }

  void _showLog() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogCycleSheet(onSaved: _load),
    );
  }
}

class _LogCycleSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _LogCycleSheet({required this.onSaved});
  @override State<_LogCycleSheet> createState() => _LogCycleSheetState();
}

class _LogCycleSheetState extends State<_LogCycleSheet> {
  String _start = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _end   = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 5)));
  String _flow  = 'Medium';
  final _notesCtrl = TextEditingController();
  final List<String> _symptoms = [];
  bool _loading = false;

  static const _allSymptoms = ['Cramps', 'Headache', 'Bloating', 'Fatigue', 'Mood swings', 'Back pain', 'Nausea'];

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final startDt = DateTime.parse(_start);
      final endDt   = DateTime.parse(_end);
      await ApiService.addCycle({
        'start_date': _start, 'end_date': _end,
        'cycle_length': 28, // default — backend can recalculate from history
        'flow_intensity': _flow,
        'symptoms': _symptoms,
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) { if (mounted) showHMToast(context, e.toString(), isError: true); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? DateTime.parse(_start) : DateTime.parse(_end),
      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(
            primary: Color(0xFFff6eb4), surface: HMColors.surface)),
        child: child!),
    );
    if (d != null) setState(() {
      if (isStart) _start = DateFormat('yyyy-MM-dd').format(d);
      else _end = DateFormat('yyyy-MM-dd').format(d);
    });
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
          const Text('Log Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _DatePicker(label: 'Start Date', value: _start, onTap: () => _pickDate(true))),
            const SizedBox(width: 12),
            Expanded(child: _DatePicker(label: 'End Date', value: _end, onTap: () => _pickDate(false))),
          ]),
          const SizedBox(height: 16),
          const Text('FLOW INTENSITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: HMColors.text3, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(children: ['Light', 'Medium', 'Heavy', 'Spotting'].map((f) {
            final sel = f == _flow;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _flow = f),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0x22ff6eb4) : HMColors.bg3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: sel ? const Color(0xFFff6eb4) : HMColors.border2),
                ),
                child: Text(f, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFFff6eb4) : HMColors.text3)),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),
          const Text('SYMPTOMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: HMColors.text3, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: _allSymptoms.map((s) {
            final sel = _symptoms.contains(s);
            return GestureDetector(
              onTap: () => setState(() => sel ? _symptoms.remove(s) : _symptoms.add(s)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? const Color(0x22ff6eb4) : HMColors.bg3,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? const Color(0xFFff6eb4) : HMColors.border2),
                ),
                child: Text(s, style: TextStyle(fontSize: 12,
                    color: sel ? const Color(0xFFff6eb4) : HMColors.text2,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }).toList()),
          const SizedBox(height: 14),
          HMTextField(label: 'Notes', hint: 'Optional notes', controller: _notesCtrl),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Save Period Log', onTap: _save, loading: _loading,
                  color: const Color(0xFFff6eb4))),
        ]),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DatePicker({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: HMColors.text3, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: HMColors.bg3,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HMColors.border2),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: HMColors.text3),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontSize: 13, color: HMColors.text)),
          ]),
        ),
      ]),
    );
  }
}
