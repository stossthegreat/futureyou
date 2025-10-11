import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Timezone init
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'models/habit.dart';
import 'services/alarm_service.dart';
import 'services/local_storage.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'design/theme.dart';
import 'logic/habit_engine.dart';

Future<void> _initTimezone() async {
  try {
    tzdata.initializeTimeZones();
    final String localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezones
  tzdata.initializeTimeZones();

  // Alarm + notifications (Android only)
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AndroidAlarmManager.initialize();
  }

  final plugin = flutterLocalNotificationsPlugin;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const settings = InitializationSettings(android: androidInit, iOS: iosInit);
  await plugin.initialize(settings);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    const androidChannel = AndroidNotificationChannel(
      'futureyou_channel',
      'Future You OS',
      description: 'Habit reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Hive setup
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }
  await LocalStorageService.initialize();

  // Timezone + alarms
  await _initTimezone();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await AlarmService.initialize();
    await AlarmService.scheduleDailyCheck();
  }

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: FutureYouApp()));
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!mounted) return;
      setState(() {
        _showOnboarding = !hasSeenOnboarding;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Prefs load error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _completeOnboarding() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_seen_onboarding', true);
    });
    if (mounted) {
      setState(() => _showOnboarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 Building AppRouter | loading=$_isLoading | onboarding=$_showOnboarding');

    // --- Visual fallback (never blank) ---
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Loading...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    if (_showOnboarding) {
      debugPrint('🟢 Showing OnboardingScreen');
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    debugPrint('🟢 Showing MainScreen');
    return const MainScreen();
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Future You OS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'App is working!',
              style: TextStyle(
                color: Colors.green,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: const Text('Go to Main App'),
            ),
          ],
        ),
      ),
    );
  }
}
