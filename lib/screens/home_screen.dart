import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants.dart';
import '../models/schedule.dart';
import '../app_services.dart';
import '../utils/responsive.dart';
import 'auth_screen.dart';
import '../widgets/time_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final storage = storageService;
  final auth = authService;
  final alarms = alarmService;

  bool authReady = false;
  String? sessionEmail;
  Schedule? schedule;
  String selectedDay = 'Monday';
  int scheduledCount = 0;
  String status = 'Initializing...';

  // editor
  bool showEditor = false;
  List<PeriodEntry> editPeriods = [];
  Map<String, List<TimetableEntry>> editTimetable = {};
  String editingDay = 'Monday';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sess = await auth.sessionAccount();
    if (sess != null) sessionEmail = sess.email;
    authReady = true;
    final s = await storage.loadSchedule();
    schedule = s;
    status = 'Ready - edit periods and schedule alarms';
    if (mounted) setState(() {});
    // Request permissions
    await alarms.requestPermission();
    await alarms.requestExactAlarm();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final granted = await alarms.isExactAlarmGranted();
    if (!granted && mounted) {
      setState(() => status = 'Exact alarm permission not granted - alarms may be delayed');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Alarm permission needed'),
          content: const Text('To fire alarms on time, please allow "Alarms & reminders" permission for this app in system settings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            TextButton(onPressed: () { Navigator.pop(context); alarms.requestExactAlarm(); }, child: const Text('Open settings')),
          ],
        ),
      );
    }
  }

  Schedule get currentSchedule => schedule ?? Schedule.blank();

  Future<void> _onSignedIn() async {
    final sess = await auth.sessionAccount();
    setState(() => sessionEmail = sess?.email);
  }

  Future<void> _signOut() async {
    await auth.signOut();
    setState(() => sessionEmail = null);
  }

  void _openEditor() {
    editPeriods = currentSchedule.periods.map((p) => PeriodEntry(period: p.period, time: p.time, name: p.name)).toList();
    editTimetable = {};
    for (final d in days) {
      editTimetable[d] = (currentSchedule.timetable[d] ?? []).map((e) => TimetableEntry(period: e.period, subject: e.subject, faculty: e.faculty)).toList();
    }
    editingDay = 'Monday';
    setState(() => showEditor = true);
  }

  void _closeEditor() => setState(() => showEditor = false);

  void _addPeriod() {
    final next = editPeriods.length + 1;
    editPeriods.add(PeriodEntry(period: next, time: '09:00-09:45', name: 'Period $next'));
    for (final d in days) {
      editTimetable[d] = editTimetable[d] ?? [];
      editTimetable[d]!.add(TimetableEntry(period: next));
    }
    setState(() {});
  }

  void _removePeriod(int index) {
    editPeriods.removeAt(index);
    for (final d in days) {
      if (editTimetable[d] != null && index < editTimetable[d]!.length) {
        editTimetable[d]!.removeAt(index);
      }
    }
    for (var i = 0; i < editPeriods.length; i++) {
      editPeriods[i].period = i + 1;
    }
    for (final d in days) {
      final list = editTimetable[d];
      if (list != null) {
        for (var i = 0; i < list.length; i++) list[i].period = i + 1;
      }
    }
    setState(() {});
  }

  Future<void> _saveAndReschedule() async {
    for (final p in editPeriods) {
      final parts = p.time.split('-');
      if (parts.length != 2) {
        _alert('Invalid Time', 'Period ${p.period} has invalid time format.');
        return;
      }
    }
    setState(() => saving = true);
    final updated = Schedule(
      periods: List.generate(editPeriods.length, (i) => PeriodEntry(period: i + 1, time: editPeriods[i].time, name: editPeriods[i].name)),
      timetable: {},
    );
    // rebuild timetable aligned
    final newTt = <String, List<TimetableEntry>>{};
    for (final d in days) {
      final src = editTimetable[d] ?? [];
      final list = <TimetableEntry>[];
      for (var i = 0; i < updated.periods.length; i++) {
        final e = (i < src.length) ? src[i] : TimetableEntry(period: i + 1);
        list.add(TimetableEntry(period: i + 1, subject: e.subject, faculty: e.faculty));
      }
      newTt[d] = list;
    }
    updated.timetable = newTt;

    await storage.saveSchedule(updated);
    final n = await alarms.scheduleAll(updated);
    setState(() {
      schedule = updated;
      scheduledCount = n;
      status = 'Scheduled $n period alarms';
      saving = false;
      showEditor = false;
    });
  }

  void _alert(String t, String m) {
    showDialog(context: context, builder: (_) => AlertDialog(title: Text(t), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  Future<void> _scheduleAll() async {
    setState(() => saving = true);
    final n = await alarms.scheduleAll(currentSchedule);
    setState(() { scheduledCount = n; status = 'Scheduled $n period alarms'; saving = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (!authReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (sessionEmail == null) {
      return AuthScreen(auth: auth, onSignedIn: _onSignedIn);
    }
    final isSmall = MediaQuery.of(context).size.width < 360;
    final titleSize = isSmall ? 18.0 : 22.0;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(R.pad(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Period Timer — Timetable', style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text(status, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(child: Text('Signed in: $sessionEmail', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                onPressed: _signOut,
                                child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: days.map((d) {
                              final active = selectedDay == d;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () => setState(() => selectedDay = d),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: active ? Colors.blue : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                                    child: Text(d.substring(0, 3), style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(R.pad(context)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedDay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ...currentSchedule.periods.asMap().entries.map((e) {
                                  final idx = e.key;
                                  final p = e.value;
                                  final entry = (currentSchedule.timetable[selectedDay] != null && idx < currentSchedule.timetable[selectedDay]!.length)
                                      ? currentSchedule.timetable[selectedDay]![idx]
                                      : TimetableEntry(period: p.period);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(14)), child: Center(child: Text('${p.period}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.name.isEmpty ? 'Period ${p.period}' : p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text(_formatRange(p.time), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(entry.subject, style: const TextStyle(fontSize: 12, color: Colors.black)),
                                            Text(entry.faculty, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 8),
                        Text('Scheduled: $scheduledCount alarms', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              await alarms.scheduleTestAlarm();
                              if (mounted) setState(() => status = 'Test alarm set for 1 minute from now');
                            },
                            child: const Text('Test alarm (1 min)', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(R.gap(context)),
                  decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))]),
                  child: Row(
                    children: [
                      Expanded(child: _bottomBtn('Edit Periods', 'Change times & names', _openEditor)),
                      const SizedBox(width: 8),
                      Expanded(child: _bottomBtn('Schedule Alarms', 'Set buzzer alarms', _scheduleAll, disabled: saving)),
                    ],
                  ),
                ),
              ],
            ),
            if (showEditor) _editorModal(),
          ],
        ),
      ),
    );
  }

  Widget _bottomBtn(String label, String hint, VoidCallback onPressed, {bool disabled = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      onPressed: disabled ? null : onPressed,
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(hint, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatRange(String time) {
    final parts = time.split('-');
    if (parts.length != 2) return time;
    return '${_to12(parts[0].trim())} - ${_to12(parts[1].trim())}';
  }

  String _to12(String t) {
    final hm = t.split(':');
    if (hm.length != 2) return t;
    final h = int.tryParse(hm[0]) ?? 0;
    final m = int.tryParse(hm[1]) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    var hh = h % 12;
    if (hh == 0) hh = 12;
    return '$hh:${m.toString().padLeft(2, '0')} $period';
  }

  Widget _editorModal() {
    return Positioned.fill(
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(child: Text('Edit Periods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: _closeEditor, icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: days.map((d) {
                    final active = editingDay == d;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => editingDay = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: active ? Colors.blue : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                          child: Text(d.substring(0, 3), style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ...editPeriods.asMap().entries.map((e) {
                      final index = e.key;
                      final p = e.value;
                      final entry = (editTimetable[editingDay] != null && index < editTimetable[editingDay]!.length)
                          ? editTimetable[editingDay]![index]
                          : TimetableEntry(period: index + 1);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(R.pad(context)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)), child: Text('P${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  const Spacer(),
                                  IconButton(onPressed: () => _removePeriod(index), icon: const Icon(Icons.delete, color: Colors.red)),
                                ],
                              ),
                              const Text('Period Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(controller: TextEditingController(text: p.name)..selection = TextSelection.collapsed(offset: p.name.length), onChanged: (v) => p.name = v, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g., Period 1')),
                              const SizedBox(height: 8),
                              const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              TimePicker(time24: p.time.split('-').first, onChange: (t) { final end = p.time.split('-').length > 1 ? p.time.split('-')[1] : '09:45'; p.time = '$t-$end'; setState(() {}); }),
                              const SizedBox(height: 8),
                              const Text('End Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              TimePicker(time24: p.time.split('-').length > 1 ? p.time.split('-')[1] : '09:45', onChange: (t) { final start = p.time.split('-').first; p.time = '$start-$t'; setState(() {}); }),
                              Text(_formatRange(p.time), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              Text('Subject ($editingDay)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(controller: TextEditingController(text: entry.subject)..selection = TextSelection.collapsed(offset: entry.subject.length), onChanged: (v) => entry.subject = v, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g., Mathematics')),
                              const SizedBox(height: 8),
                              Text('Faculty ($editingDay)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              TextField(controller: TextEditingController(text: entry.faculty)..selection = TextSelection.collapsed(offset: entry.faculty.length), onChanged: (v) => entry.faculty = v, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g., Dr. Smith')),
                            ],
                          ),
                        ),
                      );
                    }),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: _addPeriod,
                      child: const Text('+ Add Period'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: saving ? null : _saveAndReschedule,
                        child: Text(saving ? 'Saving...' : 'Save & Schedule', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _closeEditor,
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}