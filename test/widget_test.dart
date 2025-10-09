import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:future_you_os/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: FutureYouApp()));

    // Verify that the app starts without crashing
    expect(find.text('Future U OS'), findsOneWidget);
    expect(find.text('Unicorn Habit System'), findsOneWidget);
  });
}