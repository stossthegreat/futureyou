import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/habit_engine.dart';
import '../services/local_storage.dart';

final habitEngineProvider = ChangeNotifierProvider<HabitEngine>((ref) {
  final engine = HabitEngine(LocalStorageService());
  // Auto-load habits when provider is created
  engine.loadHabits();
  return engine;
});
