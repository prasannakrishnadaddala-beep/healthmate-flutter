import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'appointments_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _latestVital;
  List<dynamic> _meds = [];
  List<dynamic> _dietEntries = [];
  List<dynamic> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getVitals(),
        ApiService.getMedications(),
        ApiService.getDiet(today),
        ApiService.getAppointments(),
      ]);
      if (!mounted) return;
      final vitals = results[1] as List;
      setState(() {
        _profile     = results[0] as Map<String, dynamic>;
        _latestVital = vitals.isNotEmpty ? vitals.first as Map<String, dynamic> : null;
        _meds        = results[2] as List;
        _dietEntries = results[3] as List;
        _appointments = results[4] as List;
        _loading     = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['full_name'] ?? 'there';
    final firstName = name.toString().split(' ').first;
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    final totalCal = _dietEntries.fold<int>(0, (s, e) => s + ((e['calories'] ?? 0) as int));
    final calTarget = (_profile?['calorie_target'] ?? 2000) as int;
    final medsTotal = _meds.length;
    final medsTaken = _meds.where((m) {
      final taken = m['taken'] as List? ?? [];
      return taken.any((t) => t == true);
    }).length;

    final upcoming = _appointments.where((a) {
      try {
        final d = DateTime.parse(a['date']);
        return d.isAfter(DateTime.now().subtract(const Duration(days: 1))) && a['completed'] == 0;
      } catch (_) { return false; }
    }).toList();

    return Scaffold(
      backgroundColor: HMColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: HMColors.accent,
        backgroundColor: HMColors.surface,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: HMColors.bg2,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [HMColors.bg2, HMColors.bg3],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [HMColors.accent, HMColors.accent2]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.favorite, color: Color(0xFF060b14), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$_greeting, $firstName 👋',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
                          Text(today, style: const TextStyle(fontSize: 12, color: HMColors.text3)),
                        ],
                      )),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: HMColors.text3),
                        onPressed: _load,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  for (int i = 0; i < 6; i++) ...[
                    const HMShimmerBox(height: 90),
                    const SizedBox(height: 12),
                  ]
                ])),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats row
                    Row(children: [
                      Expanded(child: HMStatCard(
                        label: 'Calories Today',
                        value: totalCal.toString(),
                        unit: 'of $calTarget kcal target',
                        valueColor: HMColors.accent,
                        progress: calTarget > 0 ? totalCal / calTarget : 0,
                        progressColor: HMColors.accent,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: HMStatCard(
                        label: 'Medications',
                        value: '$medsTaken/$medsTotal',
                        unit: 'taken today',
                        valueColor: HMColors.success,
                        progress: medsTotal > 0 ? medsTaken / medsTotal : 0,
                        progressColor: HMColors.success,
                        badge: medsTaken == medsTotal && medsTotal > 0 ? '✓ Done' : null,
                        badgeColor: HMColors.success,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // Latest Vitals
                    if (_latestVital != null) ...[
                      HMCard(
                        title: 'Latest Vitals',
                        trailing: Text(
                          _latestVital!['timestamp'] ?? '',
                          style: const TextStyle(fontSize: 11, color: HMColors.text3),
                        ),
                        child: Row(children: [
                          _VitalChip(icon: '💓', label: 'Heart Rate',
                              value: '${_latestVital!['heart_rate'] ?? '—'}', unit: 'bpm', color: HMColors.danger),
                          const SizedBox(width: 8),
                          _VitalChip(icon: '🫁', label: 'SpO₂',
                              value: '${_latestVital!['oxygen'] ?? '—'}', unit: '%', color: HMColors.accent2),
                          const SizedBox(width: 8),
                          _VitalChip(icon: '🩸', label: 'BP',
                              value: '${_latestVital!['bp_sys'] ?? '—'}/${_latestVital!['bp_dia'] ?? '—'}',
                              unit: 'mmHg', color: HMColors.accent3),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Upcoming Appointments
                    if (upcoming.isNotEmpty) ...[
                      HMCard(
                        title: 'Upcoming Appointments',
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('See all', style: TextStyle(color: HMColors.accent, fontSize: 12)),
                        ),
                        child: Column(
                          children: upcoming.take(2).map((a) => _ApptRow(appt: a)).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Medication status
                    if (_meds.isNotEmpty) ...[
                      HMCard(
                        title: "Today's Medications",
                        child: Column(
                          children: _meds.take(4).map((m) {
                            final taken = (m['taken'] as List? ?? []);
                            final allTaken = taken.isNotEmpty && taken.every((t) => t == true);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse((m['color'] ?? '#00d4c8').replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text('${m['name']} ${m['dose'] ?? ''}',
                                    style: const TextStyle(fontSize: 13, color: HMColors.text))),
                                Icon(
                                  allTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: allTaken ? HMColors.success : HMColors.text3,
                                  size: 18,
                                ),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Quick tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [HMColors.accent.withOpacity(0.08), HMColors.accent2.withOpacity(0.08)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HMColors.accent.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Text('💡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('AI Health Tip', style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: HMColors.accent)),
                            const SizedBox(height: 4),
                            Text(
                              totalCal < 1000
                                  ? 'You\'ve logged fewer calories than usual. Make sure to eat enough to meet your daily target!'
                                  : totalCal > calTarget
                                      ? 'You\'ve exceeded your calorie target today. Consider a light dinner.'
                                      : 'Great progress! You\'re on track with your calorie goals today. Keep it up!',
                              style: const TextStyle(fontSize: 12, color: HMColors.text2, height: 1.5),
                            ),
                          ],
                        )),
                      ]),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String icon, label, value, unit;
  final Color color;
  const _VitalChip({required this.icon, required this.label, required this.value,
      required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: color, fontFamily: 'DM Mono')),
        Text(unit, style: const TextStyle(fontSize: 10, color: HMColors.text3)),
      ]),
    ));
  }
}

class _ApptRow extends StatelessWidget {
  final Map<String, dynamic> appt;
  const _ApptRow({required this.appt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: HMColors.accent2.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: HMColors.accent2.withOpacity(0.2)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(appt['date']?.toString().substring(8) ?? '--',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: HMColors.accent2)),
            Text(
              () {
                try {
                  return DateFormat('MMM').format(DateTime.parse(appt['date']));
                } catch (_) { return ''; }
              }(),
              style: const TextStyle(fontSize: 10, color: HMColors.text3),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Dr. ${appt['doctor_name'] ?? ''}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HMColors.text)),
          Text('${appt['specialty'] ?? ''} · ${appt['time'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: HMColors.text3)),
        ])),
      ]),
    );
  }
}
