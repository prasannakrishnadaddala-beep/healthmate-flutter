import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'diet_screen.dart';
import 'vitals_screen.dart';
import 'medications_screen.dart';
import 'chat_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';
import 'records_screen.dart';
import 'contacts_screen.dart';
import 'cycle_screen.dart';
import 'auth_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final List<_NavItem> _items = [
    _NavItem(icon: Icons.dashboard_rounded,     label: 'Dashboard',  screen: const DashboardScreen()),
    _NavItem(icon: Icons.monitor_heart_rounded, label: 'Vitals',     screen: const VitalsScreen()),
    _NavItem(icon: Icons.restaurant_rounded,    label: 'Diet',       screen: const DietScreen()),
    _NavItem(icon: Icons.medication_rounded,    label: 'Meds',       screen: const MedicationsScreen()),
    _NavItem(icon: Icons.smart_toy_rounded,     label: 'AI Chat',    screen: const ChatScreen()),
  ];

  void _navigate(Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: IndexedStack(index: _index, children: _items.map((e) => e.screen).toList()),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: HMColors.bg2,
          border: Border(top: BorderSide(color: HMColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected ? HMColors.accent.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(_items[i].icon,
                              color: selected ? HMColors.accent : HMColors.text3, size: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(_items[i].label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                                color: selected ? HMColors.accent : HMColors.text3)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: HMColors.bg2,
      child: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [HMColors.accent, HMColors.accent2]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.favorite, color: Color(0xFF060b14), size: 24),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HealthMate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: HMColors.text)),
                Text('Personal Health Companion', style: TextStyle(fontSize: 11, color: HMColors.text3)),
              ]),
            ]),
          ),
          Container(height: 1, color: HMColors.border),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            _DrawerSection('Main'),
            _DrawerTile(icon: Icons.dashboard_rounded,     label: 'Dashboard',
                onTap: () { Navigator.pop(context); setState(() => _index = 0); }),
            _DrawerTile(icon: Icons.monitor_heart_rounded, label: 'Vitals',
                onTap: () { Navigator.pop(context); setState(() => _index = 1); }),
            _DrawerTile(icon: Icons.restaurant_rounded,    label: 'Diet & Nutrition',
                onTap: () { Navigator.pop(context); setState(() => _index = 2); }),
            _DrawerTile(icon: Icons.medication_rounded,    label: 'Medications',
                onTap: () { Navigator.pop(context); setState(() => _index = 3); }),
            _DrawerTile(icon: Icons.smart_toy_rounded,     label: 'AI Health Chat',
                onTap: () { Navigator.pop(context); setState(() => _index = 4); }),
            const SizedBox(height: 4),
            _DrawerSection('More'),
            _DrawerTile(icon: Icons.calendar_today_rounded, label: 'Appointments',
                onTap: () => _navigate(const AppointmentsScreen())),
            _DrawerTile(icon: Icons.folder_rounded,         label: 'Health Records',
                onTap: () => _navigate(const RecordsScreen())),
            _DrawerTile(icon: Icons.water_drop_rounded,     label: 'Cycle Tracker',
                color: const Color(0xFFff6eb4),
                onTap: () => _navigate(const CycleScreen())),
            _DrawerTile(icon: Icons.contacts_rounded,       label: 'Doctors & Contacts',
                onTap: () => _navigate(const ContactsScreen())),
            const SizedBox(height: 4),
            _DrawerSection('Account'),
            _DrawerTile(icon: Icons.person_rounded, label: 'My Profile',
                onTap: () => _navigate(const ProfileScreen())),
          ])),
          Container(height: 1, color: HMColors.border),
          ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: HMColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: HMColors.danger, size: 18),
            ),
            title: const Text('Sign Out',
                style: TextStyle(color: HMColors.danger, fontSize: 14, fontWeight: FontWeight.w500)),
            onTap: _logout,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  _NavItem({required this.icon, required this.label, required this.screen});
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(title.toUpperCase(), style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700, color: HMColors.text3, letterSpacing: 0.8)),
  );
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? HMColors.text2;
    return ListTile(
      dense: true,
      horizontalTitleGap: 8,
      leading: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: c, size: 17),
      ),
      title: Text(label, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
