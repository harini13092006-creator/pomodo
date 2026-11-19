import 'package:flutter_test/flutter_test.dart';
import 'package:pomodo/core/utils/time_formatter.dart';

void main() {
  group('TimeFormatter', () {
    test('formats standard seconds into mm:ss', () {
      expect(TimeFormatter.formatTime(1500), '25:00');
      expect(TimeFormatter.formatTime(300), '05:00');
      expect(TimeFormatter.formatTime(59), '00:59');
      expect(TimeFormatter.formatTime(0), '00:00');
    });

    test('formats hours when total duration exceeds one hour', () {
      expect(TimeFormatter.formatTime(3600), '01:00:00');
      expect(TimeFormatter.formatTime(3665), '01:01:05');
    });

    test('handles negative durations gracefully', () {
      expect(TimeFormatter.formatTime(-10), '00:00');
    });

    test('formats minutes suffix string', () {
      expect(TimeFormatter.formatMinutes(25), '25 min');
    });
  });
}
