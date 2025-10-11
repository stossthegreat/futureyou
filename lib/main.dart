import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/habit.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'design/theme.dart';

final FlutterLocalNotificationsPlugin _notifier = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────────────────────────────────────────
  // 1️⃣ Init lightweight things first (never block UI)
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }

  // ───────────────────────────────────────────────
  // 2️⃣ Kick off background inits *without waiting*
  _initBackgroundServices();

  // ───────────────────────────────────────────────
  // 3️⃣ System UI setup
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ───────────────────────────────────────────────
  // 4️⃣ Launch app immediately (no delay)
  runApp(const ProviderScope(child: FutureYouApp()));
}

Future<void> _initBackgroundServices() async {
  try {
    // Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notifier.initialize(settings);

    const channel = AndroidNotificationChannel(
      'futureyou_channel',
      'Future You OS',
      description: 'Habit reminders',
      importance: Importance.max,
      playSound: true,
    );
    await _notifier
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }

  try {
    // Timezone
    tzdata.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
    debugPrint('Timezone init failed: $e');
  }

  try {
    // Alarm Manager
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await AndroidAlarmManager.initialize();
    }
  } catch (e) {
    debugPrint('AlarmManager init failed: $e');
  }
}

class FutureYouApp extends StatelessWidget {
  const FutureYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future You OS',
      theme: AppTheme.darkTheme,
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});
  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;
    if (mounted) setState(() => _showOnboarding = !seen);
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return _showOnboarding
        ? OnboardingScreen(onComplete: _completeOnboarding)
        : const MainScreen();
  }
}
