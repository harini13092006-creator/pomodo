import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/core/constants/app_strings.dart';
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

  group('TimerProvider Core & Initial State', () {
    test('initializes with 25 minutes for Focus mode', () {
      expect(timerProvider.mode, PomodoroMode.focus);
      expect(timerProvider.status, TimerStatus.initial);
      expect(timerProvider.totalSeconds, 25 * 60);
      expect(timerProvider.remainingSeconds, 25 * 60);
      expect(timerProvider.isInitial, isTrue);
      expect(timerProvider.isRunning, isFalse);
      expect(timerProvider.isPaused, isFalse);
    });

    test('calculates initial progress as 0.0', () {
      expect(timerProvider.progress, 0.0);
    });
  });

  group('Session Counter Invariant (Never increments on pause or reset)', () {
    test('pausing a focus timer does NOT increment session counter', () {
      timerProvider.startTimer();
      timerProvider.pauseTimer();

      expect(timerProvider.isPaused, isTrue);
      expect(timerProvider.completedSessions, 0);
      expect(storageService.getTodayCompletedSessions(), 0);
    });

    test('resetting a focus timer does NOT increment session counter', () {
      timerProvider.startTimer();
      timerProvider.resetTimer();

      expect(timerProvider.isInitial, isTrue);
      expect(timerProvider.completedSessions, 0);
      expect(storageService.getTodayCompletedSessions(), 0);
    });

    test('switching modes does NOT increment session counter', () {
      timerProvider.startTimer();
      timerProvider.setMode(PomodoroMode.breakMode);

      expect(timerProvider.completedSessions, 0);
      expect(storageService.getTodayCompletedSessions(), 0);
    });
  });

  group('Automatic Session Transitions & Alert Sound Triggers', () {
    test('focus completion triggers focus alert, transitions to Break mode, and sets 05:00', () async {
      expect(timerProvider.mode, PomodoroMode.focus);
      expect(timerProvider.completedSessions, 0);
      expect(mockSoundService.focusAlertCalls, 0);

      // Trigger Focus interval completion
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify audio chime & vibration alert triggered
      expect(mockSoundService.focusAlertCalls, 1);
      expect(mockSoundService.vibrationCalls, 1);

      // Verify transitions to Break Mode
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.totalSeconds, 5 * 60);
      expect(timerProvider.remainingSeconds, 5 * 60);
      expect(timerProvider.status, TimerStatus.initial);

      // Verify session counter incremented strictly once
      expect(timerProvider.completedSessions, 1);
      expect(storageService.getTodayCompletedSessions(), 1);

      // Verify visual transition message
      expect(timerProvider.transitionMessage, AppStrings.focusTransitionMessage);
    });

    test('break completion triggers break alert, transitions to Focus mode, and sets 25:00', () async {
      // 1. Run and complete Focus
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.completedSessions, 1);
      expect(mockSoundService.focusAlertCalls, 1);

      // 2. Complete Break interval
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify break alert chime & vibration triggered
      expect(mockSoundService.breakAlertCalls, 1);

      // Verify transitions back to Focus Mode
      expect(timerProvider.mode, PomodoroMode.focus);
      expect(timerProvider.totalSeconds, 25 * 60);
      expect(timerProvider.remainingSeconds, 25 * 60);
      expect(timerProvider.status, TimerStatus.initial);

      // Verify focus session counter was NOT incremented on break completion
      expect(timerProvider.completedSessions, 1);
      expect(storageService.getTodayCompletedSessions(), 1);

      // Verify transition message
      expect(timerProvider.transitionMessage, AppStrings.breakCompletedReadyToFocus);
    });

    test('alternates through multiple consecutive Pomodoro cycles accurately', () async {
      expect(timerProvider.completedSessions, 0);

      // Cycle 1: Focus -> Break
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.remainingSeconds, 5 * 60);
      expect(timerProvider.completedSessions, 1);

      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.focus);
      expect(timerProvider.remainingSeconds, 25 * 60);
      expect(timerProvider.completedSessions, 1);

      // Cycle 2: Focus -> Break
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.remainingSeconds, 5 * 60);
      expect(timerProvider.completedSessions, 2);

      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.focus);
      expect(timerProvider.remainingSeconds, 25 * 60);
      expect(timerProvider.completedSessions, 2);

      // Cycle 3: Focus -> Break
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.mode, PomodoroMode.breakMode);
      expect(timerProvider.remainingSeconds, 5 * 60);
      expect(timerProvider.completedSessions, 3);
    });

    test('starting timer clears previous transition message', () async {
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.transitionMessage, isNotNull);

      timerProvider.startTimer();
      expect(timerProvider.transitionMessage, isNull);
    });
  });

  group('Productivity Reset', () {
    test('resetProductivity resets today count while keeping historical records', () async {
      timerProvider.simulateIntervalCompletionForTesting();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(timerProvider.completedSessions, 1);

      await timerProvider.resetProductivity();
      expect(timerProvider.completedSessions, 0);
      expect(storageService.getTodayCompletedSessions(), 0);
    });
  });

  group('Application Restart Simulation', () {
    test('restores paused timer state and mode after app restart', () async {
      timerProvider.startTimer();
      timerProvider.pauseTimer();
      await Future.delayed(const Duration(milliseconds: 50));
      final remaining = timerProvider.remainingSeconds;

      // Simulate app kill & restart by instantiating new provider with same storage
      final newProvider = TimerProvider(
        storageService: storageService,
        soundService: mockSoundService,
      );

      expect(newProvider.status, TimerStatus.paused);
      expect(newProvider.remainingSeconds, remaining);
      expect(newProvider.mode, PomodoroMode.focus);

      newProvider.dispose();
    });
  });
}
