import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/core/constants/app_constants.dart';
import 'package:pomodo/models/timer_model.dart';
import 'package:pomodo/providers/timer_provider.dart';
import 'package:pomodo/services/storage_service.dart';
import 'sound_service_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings & Preferences Defaults and Clamping', () {
    test('missing local storage values cleanly fall back to app defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      expect(storage.getPomodoroDuration(), AppConstants.defaultPomodoroMinutes); // 25
      expect(storage.getShortBreakDuration(), AppConstants.defaultShortBreakMinutes); // 5
      expect(storage.getLongBreakDuration(), AppConstants.defaultLongBreakMinutes); // 15
      expect(storage.getLongBreakInterval(), AppConstants.defaultRoundsBeforeLongBreak); // 4
      expect(storage.isSoundEnabled(), isTrue);
      expect(storage.isVibrationEnabled(), isTrue);
      expect(storage.getTodayCompletedSessions(), 0);
      expect(storage.getSavedTimerState(), isNull);
    });

    test('duration clamping prevents negative or out-of-bound minutes', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      // Lower bound clamp (min is 1)
      await storage.setPomodoroDuration(0);
      expect(storage.getPomodoroDuration(), AppConstants.minMinutes); // 1

      await storage.setPomodoroDuration(-10);
      expect(storage.getPomodoroDuration(), AppConstants.minMinutes); // 1

      // Upper bound clamp (max is 120)
      await storage.setPomodoroDuration(300);
      expect(storage.getPomodoroDuration(), AppConstants.maxPomodoroMinutes); // 120

      // Break duration lower & upper clamp (min 1, max 60)
      await storage.setShortBreakDuration(-5);
      expect(storage.getShortBreakDuration(), AppConstants.minMinutes); // 1

      await storage.setShortBreakDuration(999);
      expect(storage.getShortBreakDuration(), AppConstants.maxBreakMinutes); // 60
    });
  });

  group('Settings Persistence Across App Restarts', () {
    test('custom focus and break durations persist and update TimerProvider', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      await storage.setPomodoroDuration(50);
      await storage.setShortBreakDuration(10);
      await storage.setSoundEnabled(false);
      await storage.setVibrationEnabled(false);

      // Simulate app restart by re-initializing with same prefs
      final restartedStorage = await StorageService.init();
      expect(restartedStorage.getPomodoroDuration(), 50);
      expect(restartedStorage.getShortBreakDuration(), 10);
      expect(restartedStorage.isSoundEnabled(), isFalse);
      expect(restartedStorage.isVibrationEnabled(), isFalse);

      final mockSound = MockSoundService();
      final provider = TimerProvider(
        storageService: restartedStorage,
        soundService: mockSound,
      );

      // Check initial provider state reflects customized duration (50 minutes = 3000s)
      expect(provider.remainingSeconds, 50 * 60);
      expect(provider.totalSeconds, 50 * 60);

      // Switch to break mode reflects customized break duration (10 minutes = 600s)
      provider.setMode(PomodoroMode.breakMode);
      expect(provider.remainingSeconds, 10 * 60);
      expect(provider.totalSeconds, 10 * 60);

      provider.dispose();
    });

    test('updating durations dynamically refreshes initial timer duration', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final mockSound = MockSoundService();
      final provider = TimerProvider(
        storageService: storage,
        soundService: mockSound,
      );

      expect(provider.remainingSeconds, 25 * 60);

      // Update in storage and notify provider
      await storage.setPomodoroDuration(35);
      provider.updateDurations();

      expect(provider.remainingSeconds, 35 * 60);
      expect(provider.totalSeconds, 35 * 60);

      provider.dispose();
    });
  });
}
