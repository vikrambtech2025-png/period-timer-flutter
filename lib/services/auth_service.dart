import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'storage_service.dart';
import '../models/account.dart';

class AuthService {
  final StorageService storage;
  AuthService(this.storage);

  static const int rounds = 1500;

  String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String password, String salt) {
    var input = salt + password;
    for (var i = 0; i < rounds; i++) {
      input = sha256.convert(utf8.encode(input)).toString();
    }
    return input;
  }

  bool validEmail(String e) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e.trim());

  String? validatePassword(String pw) {
    if (pw.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(pw)) return 'Password must contain a letter.';
    if (!RegExp(r'[0-9]').hasMatch(pw)) return 'Password must contain a number.';
    return null;
  }

  Future<List<Account>> accounts() => storage.loadAccounts();

  Future<Account> createAccount({required String email, required String password, String name = ''}) async {
    final e = email.trim().toLowerCase();
    if (!validEmail(e)) throw Exception('Enter a valid email address.');
    final pwErr = validatePassword(password);
    if (pwErr != null) throw Exception(pwErr);
    final list = await storage.loadAccounts();
    if (list.any((a) => a.email == e)) throw Exception('An account with this email already exists.');
    final salt = _randomSalt();
    final hash = _hash(password, salt);
    final acc = Account(
      id: _uuid(),
      email: e,
      name: name.trim().isEmpty ? e.split('@').first : name.trim(),
      salt: salt,
      hash: hash,
      rounds: rounds,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    list.add(acc);
    await storage.saveAccounts(list);
    await storage.setSession(e);
    return acc;
  }

  Future<Account> login({required String email, required String password}) async {
    final e = email.trim().toLowerCase();
    final list = await storage.loadAccounts();
    final acc = list.firstWhere((a) => a.email == e, orElse: () => throw Exception('No account found for this email.'));
    final h = _hash(password, acc.salt);
    if (h != acc.hash) throw Exception('Incorrect password.');
    await storage.setSession(e);
    return acc;
  }

  Future<Account?> sessionAccount() async {
    final email = await storage.getSessionEmail();
    if (email == null) return null;
    final list = await storage.loadAccounts();
    try {
      return list.firstWhere((a) => a.email == email);
    } catch (_) {
      await storage.clearSession();
      return null;
    }
  }

  Future<void> signOut() => storage.clearSession();

  Future<Account> resetPassword({required String email, required String newPassword}) async {
    final e = email.trim().toLowerCase();
    final pwErr = validatePassword(newPassword);
    if (pwErr != null) throw Exception(pwErr);
    final list = await storage.loadAccounts();
    final idx = list.indexWhere((a) => a.email == e);
    if (idx < 0) throw Exception('No account found for this email.');
    final salt = _randomSalt();
    final hash = _hash(newPassword, salt);
    final updated = Account(
      id: list[idx].id,
      email: list[idx].email,
      name: list[idx].name,
      salt: salt,
      hash: hash,
      rounds: rounds,
      createdAt: list[idx].createdAt,
    );
    list[idx] = updated;
    await storage.saveAccounts(list);
    await storage.setSession(e);
    return updated;
  }

  String _uuid() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    // v4-ish
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}