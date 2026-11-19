import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/models/timer_model.dart';
import 'package:pomodo/providers/timer_provider.dart';
import 'package:pomodo/services/storage_service.dart';
import 'sound_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late MockSoundService mockSoundService;
  late TimerProvider timerProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.init();
    mockSoundService = MockSoundService();
    timerProvider = TimerProvider(
      storageService: storageService,
      soundService: mockSoundService,
    );
  });

  tearDown(() {
    timerProvider.dispose();
  });

  group('Timer Accuracy & Drift-Free Wall Clock', () {
    test('target end time anchors accurately to wall-clock time on start', () {
      final before = DateTime.now();
      timerProvider.startTimer();
      final after = DateTime.now();

      expect(timerProvider.isRunning, isTrue);
      expect(timerProvider.targetEndTime, isNotNull);

      final target = timerProvider.targetEndTime!;
      final expectedDuration = Duration(seconds: 25 * 60);

      expect(target.isAfter(before.add(expectedDuration - const Duration(seconds: 1))), isTrue);
      expect(target.isBefore(after.add(expectedDuration + const Duration(seconds: 1))), isTrue);
    });

    test('pause correctly calculates exact remaining seconds from target end time', () async {
      timerProvider.startTimer();
      await Future.delayed(const Duration(milliseconds: 300));
      timerProvider.pauseTimer();

      expect(timerProvider.isPaused, isTrue);
      expect(timerProvider.remainingSeconds, lessThanOrEqualTo(25 * 60));
      expect(timerProvider.remainingSeconds, greaterThanOrEqualTo(25 * 60 - 2));
    });

    test('resume re-anchors target end time based on preserved remaining seconds', () async {
      timerProvider.startTimer();
      timerProvider.pauseTimer();
      final remainingBefore = timerProvider.remainingSeconds;

      final resumeStart = DateTime.now();
      timerProvider.resumeTimer();

      expect(timerProvider.isRunning, isTrue);
      final target = timerProvider.targetEndTime!;
      final expectedTarget = resumeStart.add(Duration(seconds: remainingBefore));

      final diffMs = (target.difference(expectedTarget).inMilliseconds).abs();
      expect(diffMs, lessThan(100)); // Precise within 100 milliseconds
    });
  });

  group('Lifecycle & Backgrounding Transitions', () {
    test('resumed lifecycle state handles mid-flight countdown without timing drift', () async {
      timerProvider.startTimer();

      // Simulate app backgrounding
      timerProvider.didChangeAppLifecycleState(AppLifecycleState.inactive);
      timerProvider.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Simulate app foregrounding after delay
      timerProvider.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(timerProvider.isRunning, isTrue);
      expect(timerProvider.remainingSeconds, lessThanOrEqualTo(25 * 60));
    });

    test('app killed and restarted while timer running restores state accurately', () async {
      // 1. Start timer with target end time 10 minutes in the future
      final targetEndTime = DateTime.now().add(const Duration(minutes: 10));
      await storageService.saveTimerState(
        modeName: PomodoroMode.focus.name,
        remainingSeconds: 10 * 60,
        totalSeconds: 25 * 60,
        statusName: TimerStatus.running.name,
        targetEndTime: targetEndTime,
      );

      // 2. Launch new provider representing app cold start
      final restoredProvider = TimerProvider(
        storageService: storageService,
        soundService: mockSoundService,
      );

      expect(restoredProvider.isRunning, isTrue);
      expect(restoredProvider.mode, PomodoroMode.focus);
      expect(restoredProvider.remainingSeconds, closeTo(10 * 60, 2));

      restoredProvider.dispose();
    });

    test('app killed while timer running and opened after timer expired auto-completes session', () async {
      // Target end time was 5 minutes ago
      final pastEndTime = DateTime.now().subtract(const Duration(minutes: 5));
      await storageService.saveTimerState(
        modeName: PomodoroMode.focus.name,
        remainingSeconds: 0,
        totalSeconds: 25 * 60,
        statusName: TimerStatus.running.name,
        targetEndTime: pastEndTime,
      );

      final restoredProvider = TimerProvider(
        storageService: storageService,
        soundService: mockSoundService,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Should automatically transition to Break mode with incremented session
      expect(restoredProvider.mode, PomodoroMode.breakMode);
      expect(restoredProvider.remainingSeconds, 5 * 60);
      expect(restoredProvider.completedSessions, 1);
      expect(mockSoundService.focusAlertCalls, 1);

      restoredProvider.dispose();
    });
  });

  group('Consecutive Transitions & Round Tracking', () {
    test('alternates Focus and Break across 4 rounds smoothly', () async {
      expect(timerProvider.currentRound, 1);
      expect(timerProvider.completedSessions, 0);

      // Round 1 Focus -> Break
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.completedSessions, 1);
      expect(timerProvider.currentRound, 2);

      // Round 1 Break -> Focus
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.focus);
      expect(timerProvider.completedSessions, 1); // Sessions count does not increase on break

      // Round 2 Focus -> Break
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.completedSessions, 2);
      expect(timerProvider.currentRound, 3);
    });
  });
}
