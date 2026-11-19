/// Operational constants, default durations, and storage keys for Pomodo.
class AppConstants {
  AppConstants._();

  // Default Durations in Minutes
  static const int defaultPomodoroMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int defaultRoundsBeforeLongBreak = 4;

  // Limits
  static const int minMinutes = 1;
  static const int maxPomodoroMinutes = 120;
  static const int maxBreakMinutes = 60;

  // Shared Preferences Storage Keys
  static const String keyPomodoroDuration = 'pomodoro_duration_minutes';
  static const String keyShortBreakDuration = 'short_break_duration_minutes';
  static const String keyLongBreakDuration = 'long_break_duration_minutes';
  static const String keyLongBreakInterval = 'long_break_interval';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyCompletedSessions = 'completed_sessions_count';

  // Productivity Tracking & Persistence Keys
  static const String keyLastActiveDate = 'last_active_date';
  static const String keyDailyHistory = 'daily_sessions_history_json';
  static const String keySavedTimerMode = 'saved_timer_mode';
  static const String keySavedRemainingSeconds = 'saved_remaining_seconds';
  static const String keySavedTotalSeconds = 'saved_total_seconds';
  static const String keySavedTimerStatus = 'saved_timer_status';
  static const String keySavedTargetEndTime = 'saved_target_end_time';
}
