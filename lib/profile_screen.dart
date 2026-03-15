import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _ageCtrl     = TextEditingController();
  final _weightCtrl  = TextEditingController();
  final _heightCtrl  = TextEditingController();
  final _goalsCtrl   = TextEditingController();
  final _condCtrl    = TextEditingController();
  final _allergyCtrl = TextEditingController();

  String _gender     = 'female';
  String _activity   = 'moderate';
  String _diet       = '';
  String _bloodGroup = '';
  bool _loading = true;
  bool _saving  = false;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _targets;
  Map<String, dynamic>? _patientCard;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getPatientCard(),
      ]);
      final p = results[0] as Map<String, dynamic>;
      final cardData = results[1] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _profile       = p;
          _patientCard   = cardData['patient_card'] as Map<String, dynamic>?;
          _nameCtrl.text    = p['full_name']  ?? '';
          _emailCtrl.text   = p['email']      ?? '';
          _ageCtrl.text     = '${p['age']     ?? ''}';
          _weightCtrl.text  = '${p['weight_kg'] ?? ''}';
          _heightCtrl.text  = '${p['height_cm'] ?? ''}';
          _goalsCtrl.text   = p['health_goals']       ?? '';
          _condCtrl.text    = p['medical_conditions'] ?? '';
          _allergyCtrl.text = p['allergies']          ?? '';
          _gender     = p['gender']         ?? 'female';
          _activity   = p['activity_level'] ?? 'moderate';
          _diet       = p['dietary_pref']   ?? '';
          _bloodGroup = p['blood_group']    ?? '';
          _loading    = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.saveProfile({
        'full_name':   _nameCtrl.text.trim(),
        'email':       _emailCtrl.text.trim(),
        'age':         int.tryParse(_ageCtrl.text)    ?? 30,
        'weight_kg':   double.tryParse(_weightCtrl.text) ?? 60,
        'height_cm':   double.tryParse(_heightCtrl.text) ?? 165,
        'gender':      _gender,
        'blood_group': _bloodGroup,
        'activity_level':     _activity,
        'health_goals':       _goalsCtrl.text.trim(),
        'medical_conditions': _condCtrl.text.trim(),
        'allergies':          _allergyCtrl.text.trim(),
        'dietary_pref':       _diet,
      });
      if (mounted) {
        setState(() { _targets = res; _saving = false; });
        showHMToast(context, 'Profile saved ✓');
        _load();
      }
    } catch (e) {
      if (mounted) {
        showHMToast(context, e.toString(), isError: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // ── Patient ID Card ─────────────────────────────────────
                  _PatientIdCard(profile: _profile ?? {}),
                  const SizedBox(height: 12),

                  // ── AI Patient Summary ──────────────────────────────────
                  if (_patientCard != null) ...[
                    _PatientSummaryCard(card: _patientCard!),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: HMColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HMColors.border),
                      ),
                      child: Row(children: [
                        const Text('🧬', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AI Patient Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: HMColors.text)),
                          SizedBox(height: 4),
                          Text('Upload health records and AI will automatically build your patient summary here.',
                              style: TextStyle(fontSize: 12, color: HMColors.text3)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Download Section ────────────────────────────────────
                  _AppDownloadCard(),
                  const SizedBox(height: 12),

                  // ── Calculated Targets ──────────────────────────────────
                  if (_targets != null || _profile?['calorie_target'] != null) ...[
                    _TargetsCard(data: _targets ?? _profile!),
                    const SizedBox(height: 12),
                  ],

                  // ── Personal Info ────────────────────────────────────────
                  HMCard(title: 'Personal Details', child: Column(children: [
                    HMTextField(label: 'Full Name', hint: 'Your full name', controller: _nameCtrl),
                    const SizedBox(height: 14),
                    HMTextField(label: 'Email', hint: 'your@email.com',
                        controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: HMTextField(label: 'Age', hint: 'years',
                          controller: _ageCtrl, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('GENDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: HMColors.text3, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Row(children: ['female', 'male'].map((g) {
                          final sel = g == _gender;
                          return Expanded(child: GestureDetector(
                            onTap: () => setState(() => _gender = g),
                            child: Container(
                              margin: EdgeInsets.only(right: g == 'female' ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? HMColors.accent.withOpacity(0.12) : HMColors.bg3,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? HMColors.accent : HMColors.border2),
                              ),
                              child: Text(g == 'female' ? '♀ F' : '♂ M',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                      color: sel ? HMColors.accent : HMColors.text3)),
                            ),
                          ));
                        }).toList()),
                      ])),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: HMTextField(label: 'Weight (kg)', hint: '60',
                          controller: _weightCtrl, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: HMTextField(label: 'Height (cm)', hint: '165',
                          controller: _heightCtrl, keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    // Blood Group
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('BLOOD GROUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: HMColors.text3, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 6, children:
                        ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((bg) {
                          final sel = bg == _bloodGroup;
                          return GestureDetector(
                            onTap: () => setState(() => _bloodGroup = sel ? '' : bg),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52, height: 40,
                              decoration: BoxDecoration(
                                color: sel ? HMColors.danger.withOpacity(0.15) : HMColors.bg3,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: sel ? HMColors.danger : HMColors.border2,
                                    width: sel ? 1.5 : 1),
                              ),
                              child: Center(child: Text(bg,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                      color: sel ? HMColors.danger : HMColors.text3,
                                      fontFamily: 'DM Mono'))),
                            ),
                          );
                        }).toList()),
                    ]),
                  ])),
                  const SizedBox(height: 12),

                  HMCard(title: 'Activity & Goals', child: Column(children: [
                    const Text('ACTIVITY LEVEL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: HMColors.text3, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      'sedentary', 'light', 'moderate', 'active', 'very_active'
                    ].map((a) {
                      final sel = a == _activity;
                      final label = a.replaceAll('_', ' ');
                      return GestureDetector(
                        onTap: () => setState(() => _activity = a),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? HMColors.accent.withOpacity(0.12) : HMColors.bg3,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? HMColors.accent : HMColors.border2),
                          ),
                          child: Text(label[0].toUpperCase() + label.substring(1),
                              style: TextStyle(fontSize: 12,
                                  color: sel ? HMColors.accent : HMColors.text2,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 14),
                    HMTextField(label: 'Health Goals', hint: 'e.g. Lose weight, manage diabetes',
                        controller: _goalsCtrl, maxLines: 2),
                  ])),
                  const SizedBox(height: 12),

                  HMCard(title: 'Medical Info', child: Column(children: [
                    HMTextField(label: 'Medical Conditions',
                        hint: 'e.g. Diabetes, Hypertension', controller: _condCtrl, maxLines: 2),
                    const SizedBox(height: 14),
                    HMTextField(label: 'Allergies',
                        hint: 'e.g. Peanuts, Shellfish', controller: _allergyCtrl),
                  ])),
                  const SizedBox(height: 20),

                  SizedBox(width: double.infinity,
                      child: HMButton(label: 'Save Profile', onTap: _save,
                          loading: _saving, icon: Icons.save_rounded)),
                ],
              ),
            ),
    );
  }
}

// ── Patient ID Card ────────────────────────────────────────────────────────────
class _PatientIdCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _PatientIdCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final pid = profile['patient_id'] ?? 'Generating…';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0d1525), Color(0xFF111d33)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HMColors.accent.withOpacity(0.25)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [HMColors.accent, HMColors.accent2]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('🏥', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('HEALTHMATE PATIENT ID', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: HMColors.text3, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Row(children: [
              Text(pid, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: HMColors.accent,
                  fontFamily: 'DM Mono', letterSpacing: 1)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: pid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient ID copied'), duration: Duration(seconds: 2)));
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: HMColors.text3),
              ),
            ]),
            Text(profile['full_name'] ?? 'Complete your profile',
                style: const TextStyle(fontSize: 12, color: HMColors.text3)),
          ])),
        ]),
        if (profile['blood_group'] != null || profile['age'] != null || profile['gender'] != null) ...[
          const SizedBox(height: 14),
          Row(children: [
            if (profile['blood_group'] != null && (profile['blood_group'] as String).isNotEmpty)
              _badge(profile['blood_group'], '🩸 Blood Group', HMColors.danger),
            if (profile['age'] != null && profile['age'].toString().isNotEmpty) ...[
              const SizedBox(width: 8),
              _badge('${profile['age']} yrs', '🎂 Age', HMColors.accent),
            ],
            if (profile['gender'] != null && (profile['gender'] as String).isNotEmpty) ...[
              const SizedBox(width: 8),
              _badge(profile['gender'] == 'female' ? '♀ Female' : '♂ Male', '👤 Gender', HMColors.accent3),
            ],
          ]),
        ],
        if ((profile['medical_conditions'] ?? '').toString().isNotEmpty ||
            (profile['allergies'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Wrap(spacing: 12, runSpacing: 4, children: [
                if ((profile['medical_conditions'] ?? '').toString().isNotEmpty)
                  Text('⚕️ ${profile['medical_conditions']}',
                      style: const TextStyle(fontSize: 11, color: HMColors.text2)),
                if ((profile['allergies'] ?? '').toString().isNotEmpty)
                  Text('⚠️ ${profile['allergies']}',
                      style: const TextStyle(fontSize: 11, color: HMColors.warning)),
              ])),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _badge(String value, String label, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: color, fontFamily: 'DM Mono')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: HMColors.text3),
          textAlign: TextAlign.center),
    ]),
  ));
}

// ── AI Patient Summary Card ────────────────────────────────────────────────────
class _PatientSummaryCard extends StatelessWidget {
  final Map<String, dynamic> card;
  const _PatientSummaryCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.accent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Row(children: [
            Text('🧬', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('AI Patient Summary', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
          ]),
          Text('${card['document_count'] ?? 1} doc${(card['document_count'] ?? 1) > 1 ? 's' : ''} · ${card['last_updated'] ?? ''}',
              style: const TextStyle(fontSize: 10, color: HMColors.text3)),
        ]),
        if (card['summary'] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0x0A00d4c8),
              border: Border(left: BorderSide(color: HMColors.accent, width: 3)),
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
            ),
            child: Text(card['summary'], style: const TextStyle(
                fontSize: 13, color: HMColors.text2, height: 1.5)),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          if ((card['conditions_identified'] as List?)?.isNotEmpty == true)
            _InfoChip(icon: '⚕️', title: 'Conditions',
                items: List<String>.from(card['conditions_identified']),
                color: HMColors.warning),
          if ((card['medications_mentioned'] as List?)?.isNotEmpty == true)
            _InfoChip(icon: '💊', title: 'Medications',
                items: List<String>.from(card['medications_mentioned']),
                color: HMColors.accent2),
          if ((card['abnormal_findings'] as List?)?.isNotEmpty == true)
            _InfoChip(icon: '⚠️', title: 'Abnormal',
                items: List<String>.from(card['abnormal_findings']),
                color: HMColors.danger),
          if ((card['recommended_followups'] as List?)?.isNotEmpty == true)
            _InfoChip(icon: '✅', title: 'Follow-ups',
                items: List<String>.from(card['recommended_followups']),
                color: HMColors.success),
        ]),
        if ((card['risk_factors'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: HMColors.warning.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HMColors.warning.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Text('⚡', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(child: Text('Risk factors: ${(card['risk_factors'] as List).join(' · ')}',
                  style: const TextStyle(fontSize: 12, color: HMColors.text2))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon, title;
  final List<String> items;
  final Color color;
  const _InfoChip({required this.icon, required this.title,
      required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HMColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HMColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$icon $title', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        ...items.take(3).map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text('• $item', style: const TextStyle(fontSize: 11, color: HMColors.text2)),
        )),
      ]),
    );
  }
}

// ── App Download Card ─────────────────────────────────────────────────────────
class _AppDownloadCard extends StatelessWidget {
  const _AppDownloadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📲', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Get the App', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
        ]),
        const SizedBox(height: 4),
        const Text('Install on your phone for the best experience',
            style: TextStyle(fontSize: 12, color: HMColors.text3)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _DlButton(
            emoji: '🤖', platform: 'Android',
            sub: 'Download APK',
            color: HMColors.success,
            onTap: () => launchUrl(Uri.parse(
                '${ApiService.baseUrl}/download/android')),
          )),
          const SizedBox(width: 10),
          Expanded(child: _DlButton(
            emoji: '🍎', platform: 'iPhone',
            sub: 'Add to Home Screen',
            color: HMColors.accent2,
            onTap: () => _showiOSDialog(context),
          )),
        ]),
      ]),
    );
  }

  void _showiOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HMColors.surface,
        title: const Row(children: [
          Text('🍎 '),
          Text('Install on iPhone', style: TextStyle(color: HMColors.text, fontSize: 16)),
        ]),
        content: const Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('To install HealthMate on your iPhone:',
              style: TextStyle(color: HMColors.text2, fontSize: 13)),
          SizedBox(height: 12),
          _Step(n: '1', text: 'Open this app\'s URL in Safari'),
          _Step(n: '2', text: 'Tap the Share ⬆️ button'),
          _Step(n: '3', text: 'Tap "Add to Home Screen" ➕'),
          _Step(n: '4', text: 'Tap Add — done!'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Got it', style: TextStyle(color: HMColors.accent))),
        ],
      ),
    );
  }
}

class _DlButton extends StatelessWidget {
  final String emoji, platform, sub;
  final Color color;
  final VoidCallback onTap;
  const _DlButton({required this.emoji, required this.platform,
      required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(platform, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            Text(sub, style: const TextStyle(fontSize: 10, color: HMColors.text3)),
          ])),
        ]),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, text;
  const _Step({required this.n, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(width: 20, height: 20,
          decoration: BoxDecoration(color: HMColors.accent.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Center(child: Text(n, style: const TextStyle(fontSize: 10,
              fontWeight: FontWeight.w700, color: HMColors.accent)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: HMColors.text2))),
    ]),
  );
}

// ── Targets Card ───────────────────────────────────────────────────────────────
class _TargetsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TargetsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          HMColors.accent.withOpacity(0.06), HMColors.accent2.withOpacity(0.06)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.accent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('🎯', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text('Daily Targets (AI Calculated)', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: HMColors.accent)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _t('🔥', '${data['calorie_target'] ?? 2000}', 'kcal', HMColors.accent),
          _t('💪', '${data['protein_target'] ?? 50}g', 'Protein', const Color(0xFF3b82f6)),
          _t('🍞', '${data['carb_target'] ?? 250}g', 'Carbs', const Color(0xFFf59e0b)),
          _t('🥑', '${data['fat_target'] ?? 65}g', 'Fat', const Color(0xFFef4444)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.water_drop_rounded, size: 13, color: HMColors.accent2),
          const SizedBox(width: 4),
          Text('${data['water_target'] ?? 2000} ml water daily',
              style: const TextStyle(fontSize: 11, color: HMColors.text2)),
        ]),
      ]),
    );
  }

  Widget _t(String emoji, String value, String label, Color color) => Expanded(
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: color, fontFamily: 'DM Mono')),
      Text(label, style: const TextStyle(fontSize: 9, color: HMColors.text3)),
    ]),
  );
}
