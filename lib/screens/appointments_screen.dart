import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> _appts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAppointments();
      if (mounted) setState(() { _appts = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _appts.where((a) => a['completed'] == 0).toList();
    final completed = _appts.where((a) => a['completed'] == 1).toList();

    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(title: const Text('Appointments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdd,
        backgroundColor: HMColors.accent,
        foregroundColor: const Color(0xFF001a1a),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load, color: HMColors.accent, backgroundColor: HMColors.surface,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
            : _appts.isEmpty
                ? const HMEmptyState(emoji: '📅', title: 'No appointments',
                    subtitle: 'Schedule your doctor appointments to get reminders')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        const Text('Upcoming', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: HMColors.text3, letterSpacing: 0.3)),
                        const SizedBox(height: 8),
                        ...upcoming.map((a) => _ApptCard(appt: a, onDelete: _load, onComplete: _load)),
                        const SizedBox(height: 16),
                      ],
                      if (completed.isNotEmpty) ...[
                        const Text('Completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: HMColors.text3, letterSpacing: 0.3)),
                        const SizedBox(height: 8),
                        ...completed.map((a) => _ApptCard(appt: a, onDelete: _load, onComplete: _load)),
                      ],
                    ],
                  ),
      ),
    );
  }

  void _showAdd() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddApptSheet(onSaved: _load),
    );
  }
}

class _ApptCard extends StatelessWidget {
  final Map<String, dynamic> appt;
  final VoidCallback onDelete, onComplete;
  const _ApptCard({required this.appt, required this.onDelete, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isCompleted = appt['completed'] == 1;
    DateTime? date;
    try { date = DateTime.parse(appt['date']); } catch (_) {}

    return Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HMColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HMColors.border),
        ),
        child: Row(children: [
          // Date box
          Container(
            width: 52, height: 56,
            decoration: BoxDecoration(
              color: HMColors.accent2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HMColors.accent2.withOpacity(0.2)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(date != null ? DateFormat('d').format(date) : '--',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: HMColors.accent2)),
              Text(date != null ? DateFormat('MMM').format(date) : '',
                  style: const TextStyle(fontSize: 10, color: HMColors.text3)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dr. ${appt['doctor_name'] ?? ''}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
            if ((appt['specialty'] ?? '').isNotEmpty)
              Text(appt['specialty'], style: const TextStyle(fontSize: 12, color: HMColors.text3)),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              if ((appt['time'] ?? '').isNotEmpty)
                _meta(Icons.access_time_rounded, appt['time']),
              if ((appt['location'] ?? '').isNotEmpty)
                _meta(Icons.location_on_rounded, appt['location']),
            ]),
            if ((appt['reason'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(appt['reason'], style: const TextStyle(fontSize: 12, color: HMColors.text2)),
            ],
          ])),
          Column(children: [
            if (!isCompleted)
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded, color: HMColors.success, size: 20),
                onPressed: () async {
                  await ApiService.updateAppointment(appt['id'], {'completed': 1});
                  onComplete();
                },
                tooltip: 'Mark complete',
              ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: HMColors.text3, size: 18),
              onPressed: () async {
                await ApiService.deleteAppointment(appt['id']);
                onDelete();
              },
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: HMColors.text3),
    const SizedBox(width: 3),
    Text(text, style: const TextStyle(fontSize: 11, color: HMColors.text3)),
  ]);
}

class _AddApptSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddApptSheet({required this.onSaved});
  @override
  State<_AddApptSheet> createState() => _AddApptSheetState();
}

class _AddApptSheetState extends State<_AddApptSheet> {
  final _docCtrl    = TextEditingController();
  final _specCtrl   = TextEditingController();
  final _locCtrl    = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _date = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
  String _time = '10:00';
  bool _loading = false;

  Future<void> _save() async {
    if (_docCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addAppointment({
        'doctor_name': _docCtrl.text.trim(),
        'specialty': _specCtrl.text.trim(),
        'date': _date, 'time': _time,
        'location': _locCtrl.text.trim(),
        'reason': _reasonCtrl.text.trim(),
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
          const Text('Add Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          HMTextField(label: "Doctor's Name", hint: 'Dr. Smith', controller: _docCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Specialty', hint: 'e.g. Cardiologist', controller: _specCtrl),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context, initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(primary: HMColors.accent, surface: HMColors.surface)),
                    child: child!),
                );
                if (d != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(d));
              },
              child: AbsorbPointer(child: HMTextField(label: 'Date', hint: _date,
                  controller: TextEditingController(text: _date))),
            )),
            const SizedBox(width: 12),
            Expanded(child: HMTextField(label: 'Time', hint: '10:00',
                controller: TextEditingController(text: _time),
                onChanged: (v) => _time = v)),
          ]),
          const SizedBox(height: 14),
          HMTextField(label: 'Location / Hospital', hint: 'Optional', controller: _locCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Reason for Visit', hint: 'Optional', controller: _reasonCtrl),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Save Appointment', onTap: _save, loading: _loading)),
        ]),
      ),
    );
  }
}
