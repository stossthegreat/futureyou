import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart'; // ← ADDED

// Timezone init
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'models/habit.dart';
import 'models/coach_message.dart';
import 'services/local_storage.dart';
import 'services/messages_service.dart';
import 'services/sync_service.dart';
import 'services/offline_queue.dart'; // QueuedRequest Hive adapter is in .g.dart part file
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'design/theme.dart';
import 'logic/habit_engine.dart';

Future<void> _initTimezone() async {
  try {
    tzdata.initializeTimeZones();
    final String localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));
    debugPrint('✅ Timezone initialized: $localTz');
  } catch (e) {
    debugPrint('⚠️ Timezone fallback to UTC: $e');
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

/// Ask Android 13+ for notification permission and (where supported) the exact-alarm app-op.
/// This does NOT show on older Androids; it’s a no-op there.
Future<void> _requestRuntimePermissions() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  // POST_NOTIFICATIONS (Android 13+)
  try {
    final notifStatus = await Permission.notification.status;
    if (notifStatus.isDenied || notifStatus.isRestricted) {
      final result = await Permission.notification.request();
      debugPrint('🔔 Notification permission: $result');
    } else {
      debugPrint('🔔 Notification permission already granted.');
    }
  } catch (e) {
    debugPrint('🔔 Notification permission check failed: $e');
  }

  // SCHEDULE_EXACT_ALARM (special app-op; may auto-grant on some OEMs)
  try {
    // `permission_handler` handles API gating internally
    final exactStatus = await Permission.scheduleExactAlarm.status;
    if (exactStatus.isDenied || exactStatus.isRestricted) {
      final res = await Permission.scheduleExactAlarm.request();
      debugPrint('⏰ Exact alarm permission: $res');
      // If still not granted, consider guiding user to settings:
      // if (!res.isGranted) await openAppSettings();
    } else {
      debugPrint('⏰ Exact alarm permission already granted.');
    }
  } catch (e) {
    debugPrint('⏰ Exact alarm permission check failed: $e');
  }
}

Future<void> main() async {
  // Wrap everything in error handler
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize timezone ONCE
    await _initTimezone();

    // Alarm + notifications (Android only)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await AndroidAlarmManager.initialize();
        debugPrint('✅ AndroidAlarmManager initialized');
      } catch (e) {
        debugPrint('⚠️ AndroidAlarmManager failed: $e');
      }
    }

    // Notifications
    try {
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
      debugPrint('✅ Notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Notifications failed: $e');
    }

    // 👉 Request runtime permissions right before showing UI
    await _requestRuntimePermissions(); // ← ADDED

    // Hive setup
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(HabitAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CoachMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(QueuedRequestAdapter());
      }
      await LocalStorageService.initialize();
      await messagesService.init();
      debugPrint('✅ Hive initialized');
      
      // Initialize sync service (Phase 4)
      await syncService.init();
    } catch (e) {
      debugPrint('❌ Hive/Sync initialization failed: $e');
      // Don't throw - let app run with degraded functionality
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
  }, (error, stack) {
    debugPrint('💥 Fatal error: $error\n$stack');
  });
}

class FutureYouApp extends StatelessWidget {
  const FutureYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future You OS',
      // Use a basic theme if custom theme fails
      theme: _getSafeTheme(),
      home: const AppRouter(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }

  ThemeData _getSafeTheme() {
    try {
      return AppTheme.darkTheme;
    } catch (e) {
      debugPrint('⚠️ Custom theme failed, using fallback: $e');
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blue,
      );
    }
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
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      debugPrint('📱 Onboarding status: $hasSeenOnboarding');
      
      if (!mounted) return;
      setState(() {
        _showOnboarding = !hasSeenOnboarding;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Prefs load error: $e');
      if (!mounted) return;
    setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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

    // Error state
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Error',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = '';
                      _isLoading = true;
                    });
                    _checkOnboardingStatus();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading state
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'Loading Future You OS...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Onboarding or main screen
    try {
      if (_showOnboarding) {
        debugPrint('🟢 Showing OnboardingScreen');
        return OnboardingScreen(onComplete: _completeOnboarding);
      }

      debugPrint('🟢 Showing MainScreen');
      return const MainScreen();
    } catch (e) {
      debugPrint('❌ Screen render error: $e');
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 48),
              const SizedBox(height: 20),
              const Text(
                'Screen Load Error',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                e.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

// Keep test screen for debugging
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
