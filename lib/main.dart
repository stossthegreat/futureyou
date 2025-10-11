import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Hive only
  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
  } catch (e) {
    debugPrint('Hive failed: $e');
  }

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text('Hive OK', style: TextStyle(color: Colors.white, fontSize: 32)),
      ),
    ),
  ));
}
