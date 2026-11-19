import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/app.dart';
import 'package:pomodo/core/constants/app_strings.dart';
import 'package:pomodo/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.init();
  });

  group('Rapid Controls Tapping & Edge Cases', () {
    testWidgets('rapid tapping between Start, Pause, Resume, and Reset does not throw or desync state', (tester) async {
      await tester.pumpWidget(PomodoApp(storageService: storageService));
      await tester.pumpAndSettle();

      final primaryActionButton = find.widgetWithText(InkWell, 'Start');

      // 1. Rapidly tap Start 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(primaryActionButton);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);

      // 2. Rapidly tap Pause
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Resume'), findsOneWidget);

      // 3. Rapidly tap Resume
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);

      // 4. Rapidly tap Reset
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switching modes while timer running cleanly resets and switches countdown', (tester) async {
      await tester.pumpWidget(PomodoApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Start focus timer
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(milliseconds: 200));

      // Switch mode to Break directly while timer is active
      await tester.tap(find.text('Break'));
      await tester.pumpAndSettle();

      expect(find.text('05:00'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Settings Screen Navigation, Custom Input Validation & Toggles', () {
    testWidgets('custom duration dialog displays validation errors for invalid numbers', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(PomodoApp(storageService: storageService));
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.settings), findsOneWidget);

      // Tap on the Focus Duration badge pill (e.g. "25 min")
      await tester.tap(find.text('25 min').first);
      await tester.pumpAndSettle();

      // Verify custom duration dialog is visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      // Enter invalid value (e.g. 0 min)
      final textField = find.byType(TextField);
      await tester.enterText(textField, '0');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Dialog should remain open and display validation error
      expect(find.text('Must be between 1 and 120 minutes'), findsOneWidget);

      // Enter out-of-bounds value (e.g. 999 min)
      await tester.enterText(textField, '999');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Must be between 1 and 120 minutes'), findsOneWidget);

      // Enter invalid alphanumeric string
      await tester.enterText(textField, 'invalid');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid number'), findsOneWidget);

      // Enter valid duration (e.g. 40 min)
      await tester.enterText(textField, '40');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Dialog should close and badge should update to "40 min"
      expect(find.text('40 min'), findsOneWidget);
      expect(storageService.getPomodoroDuration(), 40);

      // Pop back to HomeScreen
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Timer on HomeScreen should now reflect 40:00
      expect(find.text('40:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sound and vibration switches toggle settings and persist to storage', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(PomodoApp(storageService: storageService));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      final soundSwitch = find.widgetWithText(SwitchListTile, AppStrings.soundEffects);
      final vibrationSwitch = find.widgetWithText(SwitchListTile, AppStrings.vibration);

      expect(soundSwitch, findsOneWidget);
      expect(vibrationSwitch, findsOneWidget);

      // Toggle Sound off
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();
      expect(storageService.isSoundEnabled(), isFalse);

      // Toggle Vibration off
      await tester.tap(vibrationSwitch);
      await tester.pumpAndSettle();
      expect(storageService.isVibrationEnabled(), isFalse);

      // Toggle Sound back on
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();
      expect(storageService.isSoundEnabled(), isTrue);
    });
  });
}
