import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/app.dart';
import 'package:pomodo/core/constants/app_strings.dart';
import 'package:pomodo/providers/timer_provider.dart';
import 'package:pomodo/screens/home_screen.dart';
import 'package:pomodo/services/storage_service.dart';
import 'package:provider/provider.dart';
import '../unit/sound_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> saveScreenshot(GlobalKey key, WidgetTester tester, String filename) async {
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final file = File('screenshots/$filename');
      file.writeAsBytesSync(bytes);
    });
  }

  testWidgets('Capture real screenshots of all 5 Pomodo screens and states', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // ========================================================
    // 1. SCREENSHOT 1: Main Focus Timer Screen (25:00 countdown)
    // ========================================================
    SharedPreferences.setMockInitialValues({});
    var storageService = await StorageService.init();
    var soundService = MockSoundService();

    final key1 = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key1,
        child: PomodoApp(
          storageService: storageService,
          soundService: soundService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    await saveScreenshot(key1, tester, '01_main_focus_timer.png');

    // ========================================================
    // 2. SCREENSHOT 2: Break Mode (05:00 countdown)
    // ========================================================
    await tester.tap(find.text('Break'));
    await tester.pumpAndSettle();

    expect(find.text('05:00'), findsOneWidget);
    await saveScreenshot(key1, tester, '02_break_mode_timer.png');

    // ========================================================
    // 3. SCREENSHOT 3: Completed Focus Session Counter (3 sessions)
    // ========================================================
    SharedPreferences.setMockInitialValues({
      'completed_sessions_count': 3,
      'last_active_date': StorageService.formatDate(DateTime.now()),
    });
    storageService = await StorageService.init();
    soundService = MockSoundService();

    final key3 = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key3,
        child: PomodoApp(
          storageService: storageService,
          soundService: soundService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 of 4 sessions'), findsOneWidget);
    await saveScreenshot(key3, tester, '03_completed_session_counter.png');

    // ========================================================
    // 4. SCREENSHOT 4: Automatic Transition (Transition banner)
    // ========================================================
    final provider = tester.element(find.byType(HomeScreen)).read<TimerProvider>();
    provider.simulateIntervalCompletionForTesting();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.focusTransitionMessage), findsAtLeastNWidgets(1));
    await saveScreenshot(key3, tester, '04_automatic_transition.png');

    // ========================================================
    // 5. SCREENSHOT 5: Settings Screen
    // ========================================================
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settings), findsOneWidget);
    await saveScreenshot(key3, tester, '05_settings_screen.png');
  });
}
