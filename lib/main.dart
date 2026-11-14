import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'app_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await alarmService.init();
  runApp(const PeriodTimerApp());
}

class PeriodTimerApp extends StatelessWidget {
  const PeriodTimerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Period Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}