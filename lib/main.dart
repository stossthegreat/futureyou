import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool alarmInitOK = false;
  try {
    await AndroidAlarmManager.initialize();
    alarmInitOK = true;
  } catch (e) {
    debugPrint('AlarmManager failed: $e');
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          alarmInitOK ? 'Alarm Manager OK ✅' : 'Alarm Manager failed ❌',
          style: const TextStyle(color: Colors.white, fontSize: 28),
        ),
      ),
    ),
  ));
}
