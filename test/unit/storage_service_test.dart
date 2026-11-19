import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = await StorageService.init();
  });

  group('StorageService - Daily Productivity & History Tracking', () {
    test('initializes today count as 0', () {
      expect(storageService.getTodayCompletedSessions(), 0);
    });

    test('increments today count and saves history', () async {
      final now = DateTime(2026, 11, 18);
      await storageService.recordCompletedFocusSession(now: now);
      await storageService.recordCompletedFocusSession(now: now);

      expect(storageService.getTodayCompletedSessions(now: now), 2);

      final history = storageService.getHistoricalSessionCounts();
      expect(history['2026-11-18'], 2);
    });

    test('automatically resets count when calendar date changes and preserves history', () async {
      final day1 = DateTime(2026, 11, 18);
      await storageService.recordCompletedFocusSession(now: day1);
      await storageService.recordCompletedFocusSession(now: day1);
      await storageService.recordCompletedFocusSession(now: day1);

      expect(storageService.getTodayCompletedSessions(now: day1), 3);

      // Date advances to next day
      final day2 = DateTime(2026, 11, 19);
      final day2Count = storageService.getTodayCompletedSessions(now: day2);

      // Day 2 count must start at 0
      expect(day2Count, 0);

      // Historical record for Day 1 must be preserved
      final history = storageService.getHistoricalSessionCounts();
      expect(history['2026-11-18'], 3);

      // Increment day 2
      await storageService.recordCompletedFocusSession(now: day2);
      expect(storageService.getTodayCompletedSessions(now: day2), 1);

      final updatedHistory = storageService.getHistoricalSessionCounts();
      expect(updatedHistory['2026-11-18'], 3);
      expect(updatedHistory['2026-11-19'], 1);
    });

    test('resetTodaySessions resets today count without wiping previous days', () async {
      final day1 = DateTime(2026, 11, 18);
      await storageService.recordCompletedFocusSession(now: day1);
      await storageService.recordCompletedFocusSession(now: day1);

      final day2 = DateTime(2026, 11, 19);
      await storageService.recordCompletedFocusSession(now: day2);
      expect(storageService.getTodayCompletedSessions(now: day2), 1);

      // Reset day 2
      await storageService.resetTodaySessions(now: day2);
      expect(storageService.getTodayCompletedSessions(now: day2), 0);

      // Day 1 history is preserved
      final history = storageService.getHistoricalSessionCounts();
      expect(history['2026-11-18'], 2);
      expect(history['2026-11-19'], 0);
    });
  });

  group('StorageService - Data Validation & Corruption Recovery', () {
    test('handles corrupted JSON history string safely without throwing', () async {
      SharedPreferences.setMockInitialValues({
        'daily_sessions_history_json': '{corrupted_malformed_json...}',
        'completed_sessions_count': 5,
        'last_active_date': '2026-11-18',
      });
      final storage = await StorageService.init();

      final history = storage.getHistoricalSessionCounts();
      expect(history, isA<Map<String, int>>());
      expect(history.isEmpty, isTrue);

      // Operations continue normally
      expect(storage.getTodayCompletedSessions(now: DateTime(2026, 11, 18)), 5);
    });

    test('prevents negative session counts by clamping to 0', () async {
      SharedPreferences.setMockInitialValues({
        'completed_sessions_count': -10,
        'last_active_date': '2026-11-18',
      });
      final storage = await StorageService.init();

      expect(storage.getTodayCompletedSessions(now: DateTime(2026, 11, 18)), 0);
    });
  });

  group('StorageService - Timer State Persistence', () {
    test('saves and retrieves timer execution state accurately', () async {
      final targetEnd = DateTime.now().add(const Duration(minutes: 15));
      await storageService.saveTimerState(
        modeName: 'focus',
        remainingSeconds: 900,
        totalSeconds: 1500,
        statusName: 'running',
        targetEndTime: targetEnd,
      );

      final saved = storageService.getSavedTimerState();
      expect(saved, isNotNull);
      expect(saved!.modeName, 'focus');
      expect(saved.remainingSeconds, 900);
      expect(saved.totalSeconds, 1500);
      expect(saved.statusName, 'running');
      expect(saved.targetEndTime?.millisecondsSinceEpoch, targetEnd.millisecondsSinceEpoch);
    });

    test('clears saved timer state correctly', () async {
      await storageService.saveTimerState(
        modeName: 'focus',
        remainingSeconds: 900,
        totalSeconds: 1500,
        statusName: 'running',
      );
      expect(storageService.getSavedTimerState(), isNotNull);

      await storageService.clearSavedTimerState();
      expect(storageService.getSavedTimerState(), isNull);
    });
  });
}
