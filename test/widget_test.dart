import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/app.dart';
import 'package:pomodo/services/storage_service.dart';

void main() {
  testWidgets('Pomodo UI render and timer controls interaction test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(PomodoApp(storageService: storageService));
    await tester.pumpAndSettle();

    // 1. Initial State
    expect(find.text('Pomodo'), findsOneWidget);
    expect(find.text('Ready to focus?'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    // 2. Test Start -> Button transitions to 'Pause'
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pause'), findsOneWidget);

    // 3. Test Pause -> Button transitions to 'Resume'
    await tester.tap(find.text('Pause'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Resume'), findsOneWidget);

    // 4. Test Resume -> Button transitions back to 'Pause'
    await tester.tap(find.text('Resume'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pause'), findsOneWidget);

    // 5. Test Reset -> Button transitions back to 'Start' and timer is 25:00
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    // 6. Test Mode Switching to Break -> Countdown updates to 05:00
    await tester.tap(find.text('Break'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('BREAK'), findsOneWidget);

    // 7. Test Mode Switching back to Focus -> Countdown updates to 25:00
    await tester.tap(find.text('Focus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('FOCUS'), findsOneWidget);
  });

  testWidgets('Reset productivity displays confirmation dialog and resets safely', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'completed_sessions_count': 3,
      'last_active_date': StorageService.formatDate(DateTime.now()),
    });
    final storageService = await StorageService.init();

    await tester.pumpWidget(PomodoApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Verify initial completed count rendered
    expect(find.text('3 of 4 sessions'), findsOneWidget);

    // Tap reset icon on ProductivityCard
    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pumpAndSettle();

    // Verify confirmation dialog appeared
    expect(find.text("Reset Today's Progress?"), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Tap Reset in dialog
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    // Verify counter reset to 0
    expect(find.text('0 of 4 sessions'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });
}
