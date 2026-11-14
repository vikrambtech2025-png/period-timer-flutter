import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../models/account.dart';

class StorageService {
  static const _accountsKey = '@period_timer_accounts';
  static const _sessionKey = '@period_timer_session';
  static const _scheduleKey = '@period_timer_schedule';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Account>> loadAccounts() async {
    final p = await _prefs;
    final raw = p.getString(_accountsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Account.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final p = await _prefs;
    await p.setString(_accountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<String?> getSessionEmail() async {
    final p = await _prefs;
    final raw = p.getString(_sessionKey);
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return j['email'] as String?;
  }

  Future<void> setSession(String email) async {
    final p = await _prefs;
    await p.setString(_sessionKey, jsonEncode({'email': email, 'at': DateTime.now().millisecondsSinceEpoch}));
  }

  Future<void> clearSession() async {
    final p = await _prefs;
    await p.remove(_sessionKey);
  }

  Future<Schedule> loadSchedule() async {
    final p = await _prefs;
    final raw = p.getString(_scheduleKey);
    if (raw == null) return Schedule.blank();
    try {
      return Schedule.fromJsonString(raw);
    } catch (_) {
      return Schedule.blank();
    }
  }

  Future<void> saveSchedule(Schedule s) async {
    final p = await _prefs;
    await p.setString(_scheduleKey, s.toJsonString());
  }
}