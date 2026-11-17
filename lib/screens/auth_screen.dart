import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

class AuthScreen extends StatefulWidget {
  final AuthService auth;
  final VoidCallback onSignedIn;
  const AuthScreen({super.key, required this.auth, required this.onSignedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String mode = 'login'; // login | signup | reset
  List<dynamic> accounts = [];
  String selectedEmail = '';
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final newConfirmCtrl = TextEditingController();
  final resetEmailCtrl = TextEditingController();
  final resetConfirmCtrl = TextEditingController();
  bool showPw = false;
  String error = '';
  bool busy = false;
  int failed = 0;
  DateTime? cooldownUntil;
  int resetStep = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await widget.auth.accounts();
    setState(() {
      accounts = a;
      if (a.isEmpty) mode = 'signup';
      if (a.length == 1) selectedEmail = a.first.email;
    });
  }

  void _setError(String e) => setState(() => error = e);
  void _clearError() => setState(() => error = '');

  Future<void> _signup() async {
    _clearError();
    final e = emailCtrl.text;
    if (!widget.auth.validEmail(e)) { _setError('Enter a valid email address.'); return; }
    final pwErr = widget.auth.validatePassword(passCtrl.text);
    if (pwErr != null) { _setError(pwErr); return; }
    if (passCtrl.text != confirmCtrl.text) { _setError('Passwords do not match.'); return; }
    setState(() => busy = true);
    try {
      await widget.auth.createAccount(email: e, password: passCtrl.text);
      widget.onSignedIn();
    } catch (ex) {
      _setError(ex.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => busy = false);
    }
  }

  bool get inCooldown => cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);
  int get cooldownSec => cooldownUntil == null ? 0 : cooldownUntil!.difference(DateTime.now()).inSeconds.clamp(0, 999);

  Future<void> _login() async {
    _clearError();
    final target = selectedEmail.isNotEmpty ? selectedEmail : emailCtrl.text;
    if (!widget.auth.validEmail(target)) { _setError('Select or enter an account email.'); return; }
    if (inCooldown) { _setError('Too many attempts. Try again in ${cooldownSec}s.'); return; }
    setState(() => busy = true);
    try {
      await widget.auth.login(email: target, password: passCtrl.text);
      setState(() => failed = 0);
      widget.onSignedIn();
    } catch (ex) {
      final n = failed + 1;
      if (n >= 5) {
        setState(() { failed = 0; cooldownUntil = DateTime.now().add(const Duration(seconds: 30)); });
        _setError('Too many failed attempts. Locked for 30 seconds.');
      } else {
        setState(() => failed = n);
        _setError(ex.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _resetStart() async {
    _clearError();
    final e = resetEmailCtrl.text.trim().toLowerCase();
    if (!widget.auth.validEmail(e)) { _setError('Enter a valid email address.'); return; }
    final list = await widget.auth.accounts();
    if (!list.any((a) => a.email == e)) { _setError('No account found for this email.'); return; }
    setState(() => resetStep = 1);
  }

  void _resetConfirm() {
    _clearError();
    if (resetConfirmCtrl.text.trim().toUpperCase() != 'RESET') {
      _setError('Type "RESET" exactly to confirm.');
      return;
    }
    setState(() => resetStep = 2);
  }

  Future<void> _resetFinish() async {
    _clearError();
    final pwErr = widget.auth.validatePassword(newPassCtrl.text);
    if (pwErr != null) { _setError(pwErr); return; }
    if (newPassCtrl.text != newConfirmCtrl.text) { _setError('Passwords do not match.'); return; }
    setState(() => busy = true);
    try {
      await widget.auth.resetPassword(email: resetEmailCtrl.text, newPassword: newPassCtrl.text);
      widget.onSignedIn();
    } catch (ex) {
      _setError(ex.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(R.pad(context)),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text('Period Timer — Staff Access',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center)
                  .animate().fadeIn().slideY(begin: -0.2),
              const SizedBox(height: 6),
              const Text('Sign in to edit periods and schedule alarms',
                  style: TextStyle(color: Colors.grey), textAlign: TextAlign.center).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),
              if (mode == 'login') _loginCard(),
              if (mode == 'signup') _signupCard(),
              if (mode == 'reset') _resetCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: EdgeInsets.all(R.pad(context)), child: child),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic);

  Widget _blackBtn(String label, String hint, VoidCallback? onPressed, bool disabled) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: disabled ? null : onPressed,
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (hint.isNotEmpty) Text(hint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.96, 0.96));
  }

  Widget _input(TextEditingController c, String hint, {bool obscure = false, TextInputType? kb}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: kb,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Staff Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (accounts.isNotEmpty)
          ...accounts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () { setState(() { selectedEmail = a.email; emailCtrl.text = a.email; }); _clearError(); },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedEmail == a.email ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${a.name} (${a.email})',
                        style: TextStyle(color: selectedEmail == a.email ? Colors.white : Colors.black87)),
                  ),
                ),
              )),
        if (accounts.isEmpty) _input(emailCtrl, 'Email', kb: TextInputType.emailAddress),
        _input(passCtrl, 'Password', obscure: !showPw),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => setState(() => showPw = !showPw), child: Text(showPw ? 'Hide password' : 'Show password')),
        ),
        if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center).animate().shake(hz: 4, duration: 400.ms),
        if (inCooldown) Text('Locked for ${cooldownSec}s', style: const TextStyle(color: Colors.orange, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        _blackBtn(busy ? 'Signing in...' : 'Log In', 'Enter your staff password', _login, busy || inCooldown),
        TextButton(onPressed: () { resetEmailCtrl.text = selectedEmail.isNotEmpty ? selectedEmail : emailCtrl.text; resetStep = 0; resetConfirmCtrl.clear(); newPassCtrl.clear(); newConfirmCtrl.clear(); _clearError(); setState(() => mode = 'reset'); }, child: const Text('Forgot password?')),
        TextButton(onPressed: () { _clearError(); emailCtrl.clear(); passCtrl.clear(); confirmCtrl.clear(); setState(() => mode = 'signup'); }, child: const Text('Add a staff account')),
      ],
    ));
  }

  Widget _signupCard() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create Staff Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        _input(emailCtrl, 'Email', kb: TextInputType.emailAddress),
        _input(passCtrl, 'Password (min 8 chars, 1 letter + 1 number)', obscure: !showPw),
        _input(confirmCtrl, 'Confirm password', obscure: !showPw),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => setState(() => showPw = !showPw), child: Text(showPw ? 'Hide password' : 'Show password')),
        ),
        if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center).animate().shake(hz: 4, duration: 400.ms),
        const SizedBox(height: 6),
        _blackBtn(busy ? 'Creating...' : 'Create Account', 'Save staff login', _signup, busy),
        if (accounts.isNotEmpty)
          TextButton(onPressed: () { _clearError(); setState(() => mode = 'login'); }, child: const Text('Back to login')),
      ],
    ));
  }

  Widget _resetCard() {
    if (resetStep == 0) {
      return _card(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Enter the account email. Schedule and alarms stay untouched.',
              style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _input(resetEmailCtrl, 'Email', kb: TextInputType.emailAddress),
          if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center).animate().shake(hz: 4, duration: 400.ms),
          const SizedBox(height: 6),
          _blackBtn('Continue', 'Verify account email', _resetStart, busy),
          TextButton(onPressed: () { _clearError(); setState(() => mode = 'login'); }, child: const Text('Back to login')),
        ],
      ));
    }
    if (resetStep == 1) {
      return _card(Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Confirm Reset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Type RESET to confirm. This only clears this account\'s password.',
              style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _input(resetConfirmCtrl, 'Type "RESET"'),
          if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center).animate().shake(hz: 4, duration: 400.ms),
          const SizedBox(height: 6),
          _blackBtn('Confirm', 'Proceed to new password', _resetConfirm, busy),
          TextButton(onPressed: () { _clearError(); setState(() => resetStep = 0); }, child: const Text('Back')),
        ],
      ));
    }
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Set New Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        _input(newPassCtrl, 'New password (min 8 chars, 1 letter + 1 number)', obscure: !showPw),
        _input(newConfirmCtrl, 'Confirm new password', obscure: !showPw),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => setState(() => showPw = !showPw), child: Text(showPw ? 'Hide password' : 'Show password')),
        ),
        if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center).animate().shake(hz: 4, duration: 400.ms),
        const SizedBox(height: 6),
        _blackBtn(busy ? 'Saving...' : 'Save New Password', 'Update account password', _resetFinish, busy),
        TextButton(onPressed: () { _clearError(); setState(() => resetStep = 1); }, child: const Text('Back')),
      ],
    ));
  }
}