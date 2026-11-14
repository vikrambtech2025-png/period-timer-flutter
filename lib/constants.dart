const List<String> days = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

class DefaultPeriod {
  final int period;
  final String time;
  final String name;
  const DefaultPeriod(this.period, this.time, this.name);
}

const List<DefaultPeriod> defaultPeriods = [
  DefaultPeriod(1, "09:00-09:45", "Period 1"),
  DefaultPeriod(2, "09:45-10:35", "Period 2"),
  DefaultPeriod(3, "10:50-11:40", "Period 3"),
  DefaultPeriod(4, "11:40-12:30", "Period 4"),
  DefaultPeriod(5, "13:20-14:15", "Period 5"),
  DefaultPeriod(6, "14:15-15:10", "Period 6"),
  DefaultPeriod(7, "15:20-16:15", "Period 7"),
];

String createBlankScheduleJson() {
  // minimal, real blank schedule built in model layer
  return "";
}