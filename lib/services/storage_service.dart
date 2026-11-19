import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Data class holding persisted timer execution state across app restarts.
class SavedTimerState {
  final String modeName;
  final int remainingSeconds;
  final int totalSeconds;
  final String statusName;
  final DateTime? targetEndTime;
  final int currentRound;
  final bool isLongBreak;

  const SavedTimerState({
    required this.modeName,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.statusName,
    this.targetEndTime,
    this.currentRound = 1,
    this.isLongBreak = false,
  });
}

/// Service responsible for persistent productivity tracking, daily resets, and settings.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // JSON-backed records keep this small, offline-first app's data portable.
  List<Map<String, dynamic>> getTasks() => _readList('pomodo_tasks');
  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    await _prefs.setString('pomodo_tasks', jsonEncode(tasks));
  }
  List<Map<String, dynamic>> getFocusSessions() => _readList('pomodo_focus_sessions');
  Future<void> recordFocusSession({int durationSeconds = 1500, String? taskId}) async {
    final sessions = getFocusSessions();
    final now = DateTime.now();
    sessions.add({'id': now.microsecondsSinceEpoch.toString(), 'date': now.toIso8601String(),
      'durationSeconds': durationSeconds, 'taskId': taskId});
    await _prefs.setString('pomodo_focus_sessions', jsonEncode(sessions));
  }
  List<Map<String, dynamic>> _readList(String key) {
    try { final value = jsonDecode(_prefs.getString(key) ?? '[]');
      return value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    } catch (_) { return <Map<String, dynamic>>[]; }
  }
  int getDailyGoal() => (_prefs.getInt('pomodo_daily_goal') ?? 4).clamp(1, 20);
  Future<void> setDailyGoal(int value) async {
    await _prefs.setInt('pomodo_daily_goal', value.clamp(1, 20));
  }
  String getThemeMode() => _prefs.getString('pomodo_theme_mode') ?? 'system';
  Future<void> setThemeMode(String value) async {
    await _prefs.setString('pomodo_theme_mode', value);
  }

  /// Factory helper to initialize StorageService with SharedPreferences.
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Date Formatting Helper (YYYY-MM-DD) ---

  static String formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // --- Daily Productivity Tracking ---

  /// Retrieves today's completed focus sessions, automatically starting a new daily count
  /// when the calendar date changes and archiving historical totals.
  int getTodayCompletedSessions({DateTime? now}) {
    final currentDate = now ?? DateTime.now();
    final todayStr = formatDate(currentDate);
    final lastActiveDate = _prefs.getString(AppConstants.keyLastActiveDate);

    // Initial first-launch case
    if (lastActiveDate == null) {
      _prefs.setString(AppConstants.keyLastActiveDate, todayStr);
      final rawCount = _prefs.getInt(AppConstants.keyCompletedSessions) ?? 0;
      return rawCount < 0 ? 0 : rawCount;
    }

    // Calendar Date Changed Case: Archive and Reset
    if (lastActiveDate != todayStr) {
      _archiveDayCount(lastActiveDate);
      _prefs.setString(AppConstants.keyLastActiveDate, todayStr);
      _prefs.setInt(AppConstants.keyCompletedSessions, 0);
      return 0;
    }

    final count = _prefs.getInt(AppConstants.keyCompletedSessions) ?? 0;
    return count < 0 ? 0 : count;
  }

  /// Increments today's completed focus sessions count and updates historical records.
  Future<int> recordCompletedFocusSession({DateTime? now}) async {
    final currentDate = now ?? DateTime.now();
    final todayStr = formatDate(currentDate);

    // Ensure daily reset validation runs first
    final currentCount = getTodayCompletedSessions(now: currentDate);
    final newCount = currentCount + 1;

    // Save today's count
    await _prefs.setInt(AppConstants.keyCompletedSessions, newCount);
    await _prefs.setString(AppConstants.keyLastActiveDate, todayStr);

    // Update history map
    final history = getHistoricalSessionCounts();
    history[todayStr] = newCount;
    await _saveHistoryMap(history);

    return newCount;
  }

  /// Resets today's productivity counter to 0 while preserving historical records.
  Future<bool> resetTodaySessions({DateTime? now}) async {
    final currentDate = now ?? DateTime.now();
    final todayStr = formatDate(currentDate);

    await _prefs.setInt(AppConstants.keyCompletedSessions, 0);
    await _prefs.setString(AppConstants.keyLastActiveDate, todayStr);

    final history = getHistoricalSessionCounts();
    history[todayStr] = 0;
    await _saveHistoryMap(history);

    return true;
  }

  /// Retrieves all historical daily session counts safely.
  Map<String, int> getHistoricalSessionCounts() {
    final jsonStr = _prefs.getString(AppConstants.keyDailyHistory);
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      return <String, int>{};
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        final Map<String, int> result = {};
        for (final entry in decoded.entries) {
          final key = entry.key.toString();
          final val = entry.value;
          final int count = val is int ? val : (int.tryParse(val.toString()) ?? 0);
          result[key] = count < 0 ? 0 : count;
        }
        return result;
      }
    } catch (_) {
      // Gracefully recover on corrupt storage without throwing
    }

    return <String, int>{};
  }

  void _archiveDayCount(String dateKey) {
    final currentCount = _prefs.getInt(AppConstants.keyCompletedSessions) ?? 0;
    if (currentCount > 0) {
      final history = getHistoricalSessionCounts();
      if (!history.containsKey(dateKey) || history[dateKey]! < currentCount) {
        history[dateKey] = currentCount;
        _saveHistoryMap(history);
      }
    }
  }

  Future<bool> _saveHistoryMap(Map<String, int> history) {
    try {
      final encoded = jsonEncode(history);
      return _prefs.setString(AppConstants.keyDailyHistory, encoded);
    } catch (_) {
      return Future.value(false);
    }
  }

  // --- Timer State Persistence Across Restarts ---

  SavedTimerState? getSavedTimerState() {
    final mode = _prefs.getString(AppConstants.keySavedTimerMode);
    final remaining = _prefs.getInt(AppConstants.keySavedRemainingSeconds);
    final total = _prefs.getInt(AppConstants.keySavedTotalSeconds);
    final status = _prefs.getString(AppConstants.keySavedTimerStatus);
    final targetEndMs = _prefs.getInt(AppConstants.keySavedTargetEndTime);

    if (mode == null || remaining == null || total == null || status == null) {
      return null;
    }

    DateTime? targetEnd;
    if (targetEndMs != null && targetEndMs > 0) {
      targetEnd = DateTime.fromMillisecondsSinceEpoch(targetEndMs);
    }

    return SavedTimerState(
      modeName: mode,
      remainingSeconds: remaining < 0 ? 0 : remaining,
      totalSeconds: total <= 0 ? 1500 : total,
      statusName: status,
      targetEndTime: targetEnd,
      currentRound: (_prefs.getInt('saved_timer_round') ?? 1).clamp(1, 20),
      isLongBreak: _prefs.getBool('saved_timer_is_long_break') ?? false,
    );
  }

  Future<void> saveTimerState({
    required String modeName,
    required int remainingSeconds,
    required int totalSeconds,
    required String statusName,
    DateTime? targetEndTime,
    int currentRound = 1,
    bool isLongBreak = false,
  }) async {
    await _prefs.setString(AppConstants.keySavedTimerMode, modeName);
    await _prefs.setInt(AppConstants.keySavedRemainingSeconds, remainingSeconds < 0 ? 0 : remainingSeconds);
    await _prefs.setInt(AppConstants.keySavedTotalSeconds, totalSeconds <= 0 ? 1500 : totalSeconds);
    await _prefs.setString(AppConstants.keySavedTimerStatus, statusName);
    await _prefs.setInt('saved_timer_round', currentRound.clamp(1, 20));
    await _prefs.setBool('saved_timer_is_long_break', isLongBreak);

    if (targetEndTime != null) {
      await _prefs.setInt(AppConstants.keySavedTargetEndTime, targetEndTime.millisecondsSinceEpoch);
    } else {
      await _prefs.remove(AppConstants.keySavedTargetEndTime);
    }
  }

  Future<void> clearSavedTimerState() async {
    await _prefs.remove(AppConstants.keySavedTimerMode);
    await _prefs.remove(AppConstants.keySavedRemainingSeconds);
    await _prefs.remove(AppConstants.keySavedTotalSeconds);
    await _prefs.remove(AppConstants.keySavedTimerStatus);
    await _prefs.remove(AppConstants.keySavedTargetEndTime);
    await _prefs.remove('saved_timer_round');
    await _prefs.remove('saved_timer_is_long_break');
  }

  // --- Timer Durations (in minutes) ---

  int getPomodoroDuration() {
    final val = _prefs.getInt(AppConstants.keyPomodoroDuration) ??
        AppConstants.defaultPomodoroMinutes;
    return val.clamp(AppConstants.minMinutes, AppConstants.maxPomodoroMinutes);
  }

  Future<bool> setPomodoroDuration(int minutes) {
    final validated = minutes.clamp(AppConstants.minMinutes, AppConstants.maxPomodoroMinutes);
    return _prefs.setInt(AppConstants.keyPomodoroDuration, validated);
  }

  int getShortBreakDuration() {
    final val = _prefs.getInt(AppConstants.keyShortBreakDuration) ??
        AppConstants.defaultShortBreakMinutes;
    return val.clamp(AppConstants.minMinutes, AppConstants.maxBreakMinutes);
  }

  Future<bool> setShortBreakDuration(int minutes) {
    final validated = minutes.clamp(AppConstants.minMinutes, AppConstants.maxBreakMinutes);
    return _prefs.setInt(AppConstants.keyShortBreakDuration, validated);
  }

  int getLongBreakDuration() {
    final value = _prefs.getInt(AppConstants.keyLongBreakDuration) ??
        AppConstants.defaultLongBreakMinutes;
    return value.clamp(AppConstants.minMinutes, AppConstants.maxBreakMinutes);
  }

  Future<bool> setLongBreakDuration(int minutes) {
    return _prefs.setInt(AppConstants.keyLongBreakDuration,
        minutes.clamp(AppConstants.minMinutes, AppConstants.maxBreakMinutes));
  }

  int getLongBreakInterval() {
    return _prefs.getInt(AppConstants.keyLongBreakInterval) ??
        AppConstants.defaultRoundsBeforeLongBreak;
  }

  Future<bool> setLongBreakInterval(int count) {
    return _prefs.setInt(AppConstants.keyLongBreakInterval, count);
  }

  // --- Preferences ---

  bool isSoundEnabled() {
    return _prefs.getBool(AppConstants.keySoundEnabled) ?? true;
  }

  Future<bool> setSoundEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.keySoundEnabled, enabled);
  }

  bool isVibrationEnabled() {
    return _prefs.getBool(AppConstants.keyVibrationEnabled) ?? true;
  }

  Future<bool> setVibrationEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.keyVibrationEnabled, enabled);
  }

  bool isNotificationsEnabled() {
    return _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
  }

  Future<bool> setNotificationsEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);
  }

  // Backward compatibility alias
  int getCompletedSessionsCount() => getTodayCompletedSessions();
  Future<bool> incrementCompletedSessions() async {
    await recordCompletedFocusSession();
    return true;
  }
  Future<bool> resetCompletedSessions() => resetTodaySessions();
}
