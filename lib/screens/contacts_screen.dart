import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _doctors = [];
  List<dynamic> _emergency = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getDoctors(), ApiService.getEmergencyContacts()]);
      if (mounted) setState(() {
        _doctors   = results[0];
        _emergency = results[1];
        _loading   = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(
        title: const Text('Contacts'),
        bottom: TabBar(
          controller: _tab,
          labelColor: HMColors.accent,
          unselectedLabelColor: HMColors.text3,
          indicatorColor: HMColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: '👨‍⚕️  Doctors'), Tab(text: '🆘  Emergency')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tab.index == 0 ? _showAddDoctor() : _showAddEmergency(),
        backgroundColor: HMColors.accent,
        foregroundColor: const Color(0xFF001a1a),
        icon: const Icon(Icons.add_rounded),
        label: Text(_tab.index == 0 ? 'Add Doctor' : 'Add Contact',
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
          : TabBarView(
              controller: _tab,
              children: [
                _DoctorsList(doctors: _doctors, onDelete: _load),
                _EmergencyList(contacts: _emergency, onDelete: _load),
              ],
            ),
    );
  }

  void _showAddDoctor() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddDoctorSheet(onSaved: _load),
    );
  }

  void _showAddEmergency() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: HMColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddEmergencySheet(onSaved: _load),
    );
  }
}

// ── Doctors List ──────────────────────────────────────────────────────────────
class _DoctorsList extends StatelessWidget {
  final List<dynamic> doctors;
  final VoidCallback onDelete;
  const _DoctorsList({required this.doctors, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return const HMEmptyState(emoji: '👨‍⚕️', title: 'No doctors saved',
          subtitle: 'Save your doctors\' contact info for quick access');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: doctors.length,
      itemBuilder: (_, i) {
        final d = doctors[i] as Map<String, dynamic>;
        return _ContactCard(
          avatar: '👨‍⚕️',
          title: 'Dr. ${d['name'] ?? ''}',
          subtitle: d['specialty'] ?? '',
          phone: d['phone'],
          email: d['email'],
          extra: d['hospital'],
          color: HMColors.accent2,
          onDelete: () async {
            await ApiService.deleteDoctor(d['id']);
            onDelete();
          },
        );
      },
    );
  }
}

// ── Emergency List ────────────────────────────────────────────────────────────
class _EmergencyList extends StatelessWidget {
  final List<dynamic> contacts;
  final VoidCallback onDelete;
  const _EmergencyList({required this.contacts, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const HMEmptyState(emoji: '🆘', title: 'No emergency contacts',
          subtitle: 'Add trusted people who can be contacted in a medical emergency');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final c = contacts[i] as Map<String, dynamic>;
        return _ContactCard(
          avatar: c['is_primary'] == 1 ? '⭐' : '👤',
          title: c['name'] ?? '',
          subtitle: c['relationship'] ?? '',
          phone: c['phone'],
          email: c['email'],
          color: c['is_primary'] == 1 ? HMColors.warning : HMColors.accent3,
          badge: c['is_primary'] == 1 ? 'Primary' : null,
          onDelete: () async {
            await ApiService.deleteEmergencyContact(c['id']);
            onDelete();
          },
        );
      },
    );
  }
}

// ── Shared Contact Card ───────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final String avatar, title, subtitle;
  final String? phone, email, extra, badge;
  final Color color;
  final VoidCallback onDelete;
  const _ContactCard({required this.avatar, required this.title, required this.subtitle,
      this.phone, this.email, this.extra, this.badge, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HMColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HMColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Center(child: Text(avatar, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HMColors.text)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: HMColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!, style: const TextStyle(fontSize: 10, color: HMColors.warning, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(fontSize: 12, color: HMColors.text3)),
          if (extra != null && extra!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(extra!, style: const TextStyle(fontSize: 12, color: HMColors.text3)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (phone != null && phone!.isNotEmpty)
              _ActionBtn(icon: Icons.call_rounded, label: 'Call',
                  color: HMColors.success,
                  onTap: () => launchUrl(Uri(scheme: 'tel', path: phone))),
            if (phone != null && phone!.isNotEmpty) const SizedBox(width: 8),
            if (email != null && email!.isNotEmpty)
              _ActionBtn(icon: Icons.email_rounded, label: 'Email',
                  color: HMColors.accent2,
                  onTap: () => launchUrl(Uri(scheme: 'mailto', path: email))),
          ]),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_rounded, size: 18, color: HMColors.text3),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Add Doctor Sheet ──────────────────────────────────────────────────────────
class _AddDoctorSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddDoctorSheet({required this.onSaved});
  @override State<_AddDoctorSheet> createState() => _AddDoctorSheetState();
}

class _AddDoctorSheetState extends State<_AddDoctorSheet> {
  final _nameCtrl  = TextEditingController();
  final _specCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hospCtrl  = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addDoctor({
        'name': _nameCtrl.text.trim(), 'specialty': _specCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(), 'email': _emailCtrl.text.trim(),
        'hospital': _hospCtrl.text.trim(),
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) { if (mounted) showHMToast(context, e.toString(), isError: true); }
    finally { if (mounted) setState(() => _loading = false); }
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
          const Text('Add Doctor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          HMTextField(label: "Doctor's Name", hint: 'Dr. Sharma', controller: _nameCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Specialty', hint: 'Cardiologist', controller: _specCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Phone', hint: '+91 98765 43210', controller: _phoneCtrl,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          HMTextField(label: 'Email', hint: 'doctor@hospital.com', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          HMTextField(label: 'Hospital / Clinic', hint: 'Apollo Hospital', controller: _hospCtrl),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Save Doctor', onTap: _save, loading: _loading)),
        ]),
      ),
    );
  }
}

// ── Add Emergency Contact Sheet ───────────────────────────────────────────────
class _AddEmergencySheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddEmergencySheet({required this.onSaved});
  @override State<_AddEmergencySheet> createState() => _AddEmergencySheetState();
}

class _AddEmergencySheetState extends State<_AddEmergencySheet> {
  final _nameCtrl  = TextEditingController();
  final _relCtrl   = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isPrimary = false;
  bool _loading = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService.addEmergencyContact({
        'name': _nameCtrl.text.trim(), 'relationship': _relCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(), 'email': _emailCtrl.text.trim(),
        'is_primary': _isPrimary ? 1 : 0,
      });
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) { if (mounted) showHMToast(context, e.toString(), isError: true); }
    finally { if (mounted) setState(() => _loading = false); }
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
          const Text('Add Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
          const SizedBox(height: 16),
          HMTextField(label: 'Name', hint: 'Contact name', controller: _nameCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Relationship', hint: 'Spouse, Parent, etc.', controller: _relCtrl),
          const SizedBox(height: 14),
          HMTextField(label: 'Phone *', hint: '+91 98765 43210', controller: _phoneCtrl,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          HMTextField(label: 'Email', hint: 'Optional', controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _isPrimary = !_isPrimary),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPrimary ? HMColors.warning.withOpacity(0.08) : HMColors.bg3,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isPrimary ? HMColors.warning.withOpacity(0.3) : HMColors.border2),
              ),
              child: Row(children: [
                Icon(_isPrimary ? Icons.star_rounded : Icons.star_border_rounded,
                    color: _isPrimary ? HMColors.warning : HMColors.text3, size: 18),
                const SizedBox(width: 10),
                const Expanded(child: Text('Set as primary emergency contact',
                    style: TextStyle(fontSize: 13, color: HMColors.text2))),
                Switch(value: _isPrimary, onChanged: (v) => setState(() => _isPrimary = v),
                    activeColor: HMColors.warning),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
              child: HMButton(label: 'Save Contact', onTap: _save, loading: _loading,
                  color: HMColors.danger)),
        ]),
      ),
    );
  }
}
