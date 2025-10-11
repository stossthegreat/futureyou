import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'design/theme.dart';
import 'models/habit.dart';

// ---------- TEMP SAFE MODE ----------
//  All background services are wrapped in try/catch so that even if
//  a plugin blocks (timezone, alarm_manager, etc.), the UI still loads.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw something immediately
  runApp(const ProviderScope(child: _StartupPlaceholder()));

  try {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
  } catch (_) {}

  // System UI styling (safe)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Wait a moment, then load the real app
  await Future.delayed(const Duration(milliseconds: 300));
  runApp(const ProviderScope(child: FutureYouApp()));
}

class _StartupPlaceholder extends StatelessWidget {
  const _StartupPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          ),
        ),
      );
}
// ---------- END SAFE MODE ----------

class FutureYouApp extends StatelessWidget {
  const FutureYouApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future You OS',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('has_seen_onboarding') ?? false;
      if (!mounted) return;
      setState(() {
        _showOnboarding = !seen;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }
    return _showOnboarding
        ? OnboardingScreen(onComplete: _completeOnboarding)
        : const MainScreen();
  }
}
