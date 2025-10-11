import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models/habit.dart';

final FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }

  // Notifications
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const settings = InitializationSettings(android: androidInit, iOS: iosInit);
  await _notifier.initialize(settings);

  // 3️⃣ Timezone test
  String tzName = 'unknown';
  try {
    tzdata.initializeTimeZones();
    tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
  } catch (e) {
    debugPrint('Timezone init failed: $e');
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Timezone: $tzName',
          style: const TextStyle(color: Colors.white, fontSize: 26),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ));
}
