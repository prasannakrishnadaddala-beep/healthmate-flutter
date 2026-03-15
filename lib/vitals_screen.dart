import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class VitalsScreen extends StatefulWidget {
  const VitalsScreen({super.key});
  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  List<dynamic> _vitals = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getVitals();
      if (mounted) setState(() { _vitals = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Map<String, dynamic>? get _latest => _vitals.isNotEmpty ? _vitals.first as Map<String, dynamic> : null;

  void _showAddVital() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddVitalSheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(title: const Text('Vitals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVital,
        backgroundColor: HMColors.accent,
        foregroundColor: const Color(0xFF001a1a),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Reading', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load, color: HMColors.accent, backgroundColor: HMColors.surface,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
            : _vitals.isEmpty
                ? const HMEmptyState(emoji: '🩺', title: 'No vitals yet',
                    subtitle: 'Log your first health reading to get started')
                : CustomScrollView(slivers: [
                    // Latest vitals
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: _VitalCard(
                            icon: '💓', label: 'Heart Rate',
                            value: '${_latest?['heart_rate'] ?? '—'}', unit: 'bpm',
                            color: HMColors.danger,
                            status: _hrStatus(_latest?['heart_rate']),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _VitalCard(
                            icon: '🫁', label: 'SpO₂',
                            value: '${_latest?['oxygen'] ?? '—'}', unit: '%',
                            color: HMColors.accent2,
                            status: _spo2Status(_latest?['oxygen']),
                          )),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _VitalCard(
                            icon: '🩸', label: 'Blood Pressure',
                            value: '${_latest?['bp_sys'] ?? '—'}/${_latest?['bp_dia'] ?? '—'}',
                            unit: 'mmHg', color: HMColors.accent3,
                            status: _bpStatus(_latest?['bp_sys'], _latest?['bp_dia']),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _VitalCard(
                            icon: '🌡️', label: 'Temperature',
                            value: '${_latest?['temperature'] ?? '—'}', unit: '°F',
                            color: HMColors.warning,
                            status: _tempStatus(_latest?['temperature']),
                          )),
                        ]),
                      ]),
                    )),

                    // HR chart
                    if (_vitals.length > 1)
                      SliverToBoxAdapter(child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: HMCard(
                          title: 'Heart Rate Trend',
                          child: SizedBox(height: 140, child: _HRChart(vitals: _vitals)),
                        ),
                      )),

                    // History list
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: const Text('History', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
                    )),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final v = _vitals[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: HMColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: HMColors.border),
                            ),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(v['timestamp'] ?? '', style: const TextStyle(
                                    fontSize: 11, color: HMColors.text3)),
                                const SizedBox(height: 6),
                                Wrap(spacing: 10, runSpacing: 4, children: [
                                  if (v['heart_rate'] != null)
                                    _chip('💓 ${v['heart_rate']} bpm', HMColors.danger),
                                  if (v['oxygen'] != null)
                                    _chip('🫁 ${v['oxygen']}%', HMColors.accent2),
                                  if (v['bp_sys'] != null)
                                    _chip('🩸 ${v['bp_sys']}/${v['bp_dia']}', HMColors.accent3),
                                  if (v['temperature'] != null)
                                    _chip('🌡️ ${v['temperature']}°F', HMColors.warning),
                                ]),
                              ])),
                            ]),
                          );
                        },
                        childCount: _vitals.length,
                      )),
                    ),
                  ]),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
  );

  String _hrStatus(dynamic v) {
    if (v == null) return '';
    final hr = (v as num).toInt();
    if (hr < 60) return 'Low';
    if (hr > 100) return 'High';
    return 'Normal';
  }
  String _spo2Status(dynamic v) {
    if (v == null) return '';
    final sp = (v as num).toDouble();
    if (sp < 95) return 'Low';
    return 'Normal';
  }
  String _bpStatus(dynamic s, dynamic d) {
    if (s == null) return '';
    final sys = (s as num).toInt();
    if (sys >= 140) return 'High';
    if (sys < 90) return 'Low';
    return 'Normal';
  }
  String _tempStatus(dynamic v) {
    if (v == null) return '';
    final t = (v as num).toDouble();
    if (t >= 100.4) return 'Fever';
    if (t < 97) return 'Low';
    return 'Normal';
  }
}

class _VitalCard extends StatelessWidget {
  final String icon, label, value, unit;
  final Color color;
  final String status;
  const _VitalCard({required this.icon, required this.label, required this.value,
      required this.unit, required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const Spacer(),
          if (status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (status == 'Normal' ? HMColors.success : HMColors.warning).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: status == 'Normal' ? HMColors.success : HMColors.warning)),
            ),
        ]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
            color: color, fontFamily: 'DM Mono')),
        Text(unit, style: const TextStyle(fontSize: 11, color: HMColors.text3)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: HMColors.text2)),
      ]),
    );
  }
}

class _HRChart extends StatelessWidget {
  final List<dynamic> vitals;
  const _HRChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    final points = vitals.reversed
        .where((v) => v['heart_rate'] != null)
        .take(10)
        .toList();
    if (points.isEmpty) return const SizedBox();
    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(color: HMColors.border, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: HMColors.text3)))),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: List.generate(points.length, (i) =>
            FlSpot(i.toDouble(), (points[i]['heart_rate'] as num).toDouble())),
        isCurved: true,
        color: HMColors.danger,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true,
            color: HMColors.danger.withOpacity(0.08)),
      )],
    ));
  }
}

// ── Add Vital Sheet ───────────────────────────────────────────────────────────
class _AddVitalSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddVitalSheet({required this.onSaved});
  @override
  State<_AddVitalSheet> createState() => _AddVitalSheetState();
}

class _AddVitalSheetState extends State<_AddVitalSheet> {
  final _o2Ctrl   = TextEditingController();
  final _hrCtrl   = TextEditingController();
  final _bpSCtrl  = TextEditingController();
  final _bpDCtrl  = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _notesCtrl= TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.addVital({
        'oxygen':      double.tryParse(_o2Ctrl.text),
        'heart_rate':  int.tryParse(_hrCtrl.text),
        'bp_sys':      int.tryParse(_bpSCtrl.text),
        'bp_dia':      int.tryParse(_bpDCtrl.text),
        'temperature': double.tryParse(_tempCtrl.text),
        'notes':       _notesCtrl.text,
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
          const Text('Log Vitals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: HMTextField(label: 'Heart Rate', hint: 'bpm', controller: _hrCtrl,
                keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: HMTextField(label: 'SpO₂', hint: '%', controller: _o2Ctrl,
                keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: HMTextField(label: 'BP Systolic', hint: 'mmHg', controller: _bpSCtrl,
                keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: HMTextField(label: 'BP Diastolic', hint: 'mmHg', controller: _bpDCtrl,
                keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 14),
          HMTextField(label: 'Temperature', hint: '°F', controller: _tempCtrl,
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          HMTextField(label: 'Notes', hint: 'Optional', controller: _notesCtrl),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Save Reading', onTap: _save, loading: _loading)),
        ]),
      ),
    );
  }
}
