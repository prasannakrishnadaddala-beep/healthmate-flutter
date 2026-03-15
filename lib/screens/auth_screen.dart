import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await ApiService.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        setState(() { _error = 'Invalid username or password.'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Logo
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HMColors.accent, HMColors.accent2]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite, color: Color(0xFF060b14), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('HealthMate', style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700, color: HMColors.text)),
                ]),
                const SizedBox(height: 8),
                const Text('Your personal AI health companion',
                    style: TextStyle(color: HMColors.text3, fontSize: 14)),
                const SizedBox(height: 48),
                const Text('Welcome back', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: HMColors.text)),
                const SizedBox(height: 4),
                const Text('Sign in to your account',
                    style: TextStyle(color: HMColors.text2, fontSize: 14)),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HMColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HMColors.danger.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: HMColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: HMColors.danger, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                HMTextField(
                  label: 'Username',
                  hint: 'Enter your username',
                  controller: _userCtrl,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                HMTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                        color: HMColors.text3, size: 18),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity,
                    child: HMButton(label: 'Sign In', onTap: _login, loading: _loading)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: HMColors.text3, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Sign up',
                        style: TextStyle(color: HMColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Register ──────────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await ApiService.register(
          _userCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim(), _emailCtrl.text.trim());
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()));
      } else {
        setState(() { _error = 'Registration failed. Username may already be taken.'; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join HealthMate', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: HMColors.text)),
                const SizedBox(height: 4),
                const Text('Create your personal health account',
                    style: TextStyle(color: HMColors.text2, fontSize: 14)),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HMColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HMColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: HMColors.danger, fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],
                HMTextField(label: 'Full Name', hint: 'Your full name', controller: _nameCtrl),
                const SizedBox(height: 14),
                HMTextField(label: 'Email', hint: 'your@email.com', controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                HMTextField(label: 'Username', hint: 'Choose a username', controller: _userCtrl,
                    validator: (v) => v!.length < 3 ? 'Min 3 characters' : null),
                const SizedBox(height: 14),
                HMTextField(label: 'Password', hint: 'Min 6 characters', controller: _passCtrl,
                    obscureText: true,
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity,
                    child: HMButton(label: 'Create Account', onTap: _register, loading: _loading)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account? ',
                      style: TextStyle(color: HMColors.text3, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('Sign in',
                        style: TextStyle(color: HMColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
