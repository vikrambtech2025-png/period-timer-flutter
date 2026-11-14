import 'package:flutter/material.dart';

class TimePicker extends StatefulWidget {
  final String time24; // "HH:MM"
  final ValueChanged<String> onChange;
  const TimePicker({super.key, required this.time24, required this.onChange});

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late TextEditingController hourCtrl;
  late TextEditingController minCtrl;
  String period = 'AM';

  @override
  void initState() {
    super.initState();
    final parts = widget.time24.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final p = h >= 12 ? 'PM' : 'AM';
    var hh = h % 12;
    if (hh == 0) hh = 12;
    period = p;
    hourCtrl = TextEditingController(text: hh.toString());
    minCtrl = TextEditingController(text: m.toString().padLeft(2, '0'));
  }

  void _emit() {
    final hh = int.tryParse(hourCtrl.text) ?? 12;
    final mm = int.tryParse(minCtrl.text) ?? 0;
    var h24 = hh % 12;
    if (period == 'PM') h24 += 12;
    final s = '${h24.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
    widget.onChange(s);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: hourCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
            onChanged: (_) => _emit(),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: TextStyle(fontSize: 18))),
        SizedBox(
          width: 60,
          child: TextField(
            controller: minCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
            onChanged: (_) => _emit(),
          ),
        ),
        const SizedBox(width: 12),
        _radio('AM'),
        _radio('PM'),
      ],
    );
  }

  Widget _radio(String p) {
    final active = period == p;
    return GestureDetector(
      onTap: () { setState(() => period = p); _emit(); },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(p, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}