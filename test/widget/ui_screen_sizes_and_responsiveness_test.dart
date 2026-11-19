import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/app.dart';
import 'package:pomodo/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.init();
  });

  Future<void> testScreenSize(
    WidgetTester tester, {
    required double width,
    required double height,
    required String deviceDescription,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(PomodoApp(storageService: storageService));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: '$deviceDescription caused an exception or overflow');
    expect(find.text('Pomodo'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Break'), findsOneWidget);

    // Switch to Break mode
    await tester.tap(find.text('Break'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: '$deviceDescription broke on mode switch');
    expect(find.text('05:00'), findsOneWidget);

    // Switch back to Focus mode
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    expect(find.text('25:00'), findsOneWidget);
  }

  group('UI Responsiveness & Screen Size Testing', () {
    testWidgets('renders perfectly on Small Android phone (320x640) with no overflow', (tester) async {
      await testScreenSize(tester, width: 320, height: 640, deviceDescription: 'Small Android Phone');
    });

    testWidgets('renders perfectly on Compact Android phone (360x800) with no overflow', (tester) async {
      await testScreenSize(tester, width: 360, height: 800, deviceDescription: 'Compact Android Phone');
    });

    testWidgets('renders perfectly on Standard Modern phone (390x844) with no overflow', (tester) async {
      await testScreenSize(tester, width: 390, height: 844, deviceDescription: 'Standard Modern Phone');
    });

    testWidgets('renders perfectly on Large Android Phablet (412x915) with no overflow', (tester) async {
      await testScreenSize(tester, width: 412, height: 915, deviceDescription: 'Large Android Phablet');
    });

    testWidgets('renders perfectly on Android Tablet (800x1280) with no overflow', (tester) async {
      await testScreenSize(tester, width: 800, height: 1280, deviceDescription: 'Android Tablet');
    });
  });
}
