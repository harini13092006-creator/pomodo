/// Utility class providing time formatting helpers for timer displays.
class TimeFormatter {
  TimeFormatter._();

  /// Formats seconds into standard 'mm:ss' or 'hh:mm:ss' representation.
  static String formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;

    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final String hoursStr = hours.toString().padLeft(2, '0');
      return '$hoursStr:$minutesStr:$secondsStr';
    }

    return '$minutesStr:$secondsStr';
  }

  /// Formats minutes into human-readable duration label (e.g., '25 min').
  static String formatMinutes(int minutes) {
    return '$minutes min';
  }
}
