import 'package:flutter_test/flutter_test.dart';
import 'package:pomodo/models/timer_model.dart';

void main() {
  group('TimerModel', () {
    test('calculates progress ratio accurately', () {
      const model = TimerModel(
        mode: PomodoroMode.focus,
        status: TimerStatus.running,
        remainingSeconds: 750,
        totalSeconds: 1500,
        currentRound: 1,
        totalRounds: 4,
      );

      expect(model.progress, 0.5);
    });

    test('progress clamp stays between 0.0 and 1.0', () {
      const initial = TimerModel(
        mode: PomodoroMode.focus,
        status: TimerStatus.initial,
        remainingSeconds: 1500,
        totalSeconds: 1500,
        currentRound: 1,
        totalRounds: 4,
      );
      expect(initial.progress, 0.0);

      const completed = TimerModel(
        mode: PomodoroMode.focus,
        status: TimerStatus.completed,
        remainingSeconds: 0,
        totalSeconds: 1500,
        currentRound: 1,
        totalRounds: 4,
      );
      expect(completed.progress, 1.0);
    });

    test('copyWith updates fields as expected', () {
      const model = TimerModel(
        mode: PomodoroMode.focus,
        status: TimerStatus.initial,
        remainingSeconds: 1500,
        totalSeconds: 1500,
        currentRound: 1,
        totalRounds: 4,
      );

      final updated = model.copyWith(
        status: TimerStatus.running,
        remainingSeconds: 1499,
      );

      expect(updated.status, TimerStatus.running);
      expect(updated.remainingSeconds, 1499);
      expect(updated.mode, PomodoroMode.focus);
    });
  });
}
