import 'dart:convert';
import '../constants.dart';

class PeriodEntry {
  int period;
  String time;
  String name;
  PeriodEntry({required this.period, required this.time, required this.name});

  factory PeriodEntry.fromJson(Map<String, dynamic> j) =>
      PeriodEntry(period: j['period'] ?? 0, time: j['time'] ?? '', name: j['name'] ?? '');
  Map<String, dynamic> toJson() => {'period': period, 'time': time, 'name': name};
}

class TimetableEntry {
  int period;
  String subject;
  String faculty;
  TimetableEntry({required this.period, this.subject = '', this.faculty = ''});

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
        period: j['period'] ?? 0,
        subject: j['subject'] ?? '',
        faculty: j['faculty'] ?? '',
      );
  Map<String, dynamic> toJson() => {'period': period, 'subject': subject, 'faculty': faculty};
}

class Schedule {
  List<PeriodEntry> periods;
  Map<String, List<TimetableEntry>> timetable;

  Schedule({required this.periods, required this.timetable});

  factory Schedule.blank() {
    final periods = defaultPeriods
        .map((p) => PeriodEntry(period: p.period, time: p.time, name: p.name))
        .toList();
    final timetable = <String, List<TimetableEntry>>{};
    for (final d in days) {
      timetable[d] = periods.map((p) => TimetableEntry(period: p.period)).toList();
    }
    return Schedule(periods: periods, timetable: timetable);
  }

  factory Schedule.fromJson(Map<String, dynamic> j) {
    final periods = (j['periods'] as List? ?? [])
        .map((e) => PeriodEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final tt = <String, List<TimetableEntry>>{};
    final src = (j['timetable'] as Map?) ?? {};
    for (final d in days) {
      final arr = src[d] ?? src[d.toLowerCase()] ?? [];
      tt[d] = (arr as List)
          .map((e) => TimetableEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      // pad
      while (tt[d]!.length < periods.length) {
        tt[d]!.add(TimetableEntry(period: tt[d]!.length + 1));
      }
      tt[d] = tt[d]!.take(periods.length).toList();
      for (var i = 0; i < tt[d]!.length; i++) {
        tt[d]![i].period = i + 1;
      }
    }
    if (periods.isEmpty) return Schedule.blank();
    return Schedule(periods: periods, timetable: tt);
  }

  Map<String, dynamic> toJson() => {
        'periods': periods.map((p) => p.toJson()).toList(),
        'timetable': timetable.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      };

  String toJsonString() => jsonEncode(toJson());
  static Schedule fromJsonString(String s) => Schedule.fromJson(jsonDecode(s));
}