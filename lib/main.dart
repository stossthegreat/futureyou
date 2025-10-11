import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/habit.dart';

final FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
  } catch (e) {
    debugPrint('Hive failed: $e');
  }

  // 2️⃣ Notifications test
  try {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifier.initialize(settings);

    // create channel
    const channel = AndroidNotificationChannel(
      'futureyou_test',
      'FutureYou Test',
      description: 'debug channel',
      importance: Importance.max,
    );
    await _notifier
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e) {
    debugPrint('Notifications failed: $e');
  }

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text('Notifications OK', style: TextStyle(color: Colors.white, fontSize: 32)),
      ),
    ),
  ));
}
