import 'dart:async';
import 'package:flutter/widgets.dart';
import '../core/constants/app_strings.dart';
import '../models/timer_model.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';

/// Provider managing high-precision Pomodoro countdowns, automatic session transitions,
/// and persistent productivity tracking across restarts and calendar date changes.
class TimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService storageService;
  final SoundService _soundService;
  final NotificationService _notificationService;

  Timer? _ticker;
  Timer? _midnightRefreshTimer;
  DateTime? _targetEndTime;
  bool _isTransitioning = false;
  bool _disposed = false;

  PomodoroMode _mode = PomodoroMode.focus;
  TimerStatus _status = TimerStatus.initial;
  String? _transitionMessage;

  int _remainingSeconds = 25 * 60;
  int _totalSeconds = 25 * 60;
  int _currentRound = 1;
  int _totalRounds = 4;
  int _completedSessions = 0;
  bool _isLongBreak = false;

  TimerProvider({
    required this.storageService,
    SoundService? soundService,
    NotificationService? notificationService,
  })  : _soundService = soundService ??
            AppSoundService(
              soundEnabled: storageService.isSoundEnabled(),
              vibrationEnabled: storageService.isVibrationEnabled(),
            ),
        _notificationService = notificationService ?? AppNotificationService() {
    WidgetsBinding.instance.addObserver(this);
    _scheduleDailyRefresh();
    _soundService.initialize();
    _loadFromStorage();
  }

  // --- Getters ---

  SoundService get soundService => _soundService;
  PomodoroMode get mode => _mode;
  TimerStatus get status => _status;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get currentRound => _currentRound;
  int get totalRounds => _totalRounds;
  int get completedSessions => _completedSessions;
  String? get transitionMessage => _transitionMessage;
  DateTime? get targetEndTime => _targetEndTime;

  bool get isRunning => _status == TimerStatus.running;
  bool get isPaused => _status == TimerStatus.paused;
  bool get isInitial => _status == TimerStatus.initial;
  bool get isCompleted => _status == TimerStatus.completed;

  /// Progress ratio from 0.0 (started) to 1.0 (completed).
  double get progress {
    if (_totalSeconds <= 0) return 0.0;
    final double elapsed = (_totalSeconds - _remainingSeconds).toDouble();
    return (elapsed / _totalSeconds).clamp(0.0, 1.0);
  }

  TimerModel get snapshot => TimerModel(
        mode: _mode,
        status: _status,
        remainingSeconds: _remainingSeconds,
        totalSeconds: _totalSeconds,
        currentRound: _currentRound,
        totalRounds: _totalRounds,
      );

  // --- Lifecycle Handling for Drift-Free Background Resumption & Daily Resets ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDailyReset();
      if (isRunning) {
        _checkTick();
      }
    }
  }

  // --- State Initialization & Persistence Loading ---

  void _loadFromStorage() {
    _totalRounds = storageService.getLongBreakInterval();
    _completedSessions = storageService.getTodayCompletedSessions();

    final saved = storageService.getSavedTimerState();
    if (saved != null) {
      _mode = saved.modeName == PomodoroMode.breakMode.name
          ? PomodoroMode.breakMode
          : PomodoroMode.focus;
      _totalSeconds = saved.totalSeconds;
      _currentRound = saved.currentRound;
      _isLongBreak = saved.isLongBreak;

      if (saved.statusName == TimerStatus.running.name && saved.targetEndTime != null) {
        final now = DateTime.now();
        if (now.isAfter(saved.targetEndTime!) || now.isAtSameMomentAs(saved.targetEndTime!)) {
          // Timer finished while application was closed
          _status = TimerStatus.running;
          _handleSessionCompletion();
          return;
        } else {
          // Re-anchor active countdown
          _targetEndTime = saved.targetEndTime;
          _status = TimerStatus.running;
          final diff = _targetEndTime!.difference(now);
          _remainingSeconds = ((diff.inMilliseconds + 999) ~/ 1000).clamp(0, _totalSeconds);
          _startTicker();
          notifyListeners();
          return;
        }
      } else if (saved.statusName == TimerStatus.paused.name) {
        _remainingSeconds = saved.remainingSeconds;
        _status = TimerStatus.paused;
        notifyListeners();
        return;
      }
    }

    // Default or fresh state for current mode
    _resetToModeDuration(_mode);
  }

  void _checkDailyReset() {
    final currentToday = storageService.getTodayCompletedSessions();
    if (currentToday != _completedSessions) {
      _completedSessions = currentToday;
      notifyListeners();
    }
  }

  void _scheduleDailyRefresh() {
    _midnightRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnightRefreshTimer = Timer(nextDay.difference(now), () {
      if (_disposed) return;
      _checkDailyReset();
      _scheduleDailyRefresh();
    });
  }

  void _persistState() {
    storageService.saveTimerState(
      modeName: _mode.name,
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
      statusName: _status.name,
      targetEndTime: _targetEndTime,
      currentRound: _currentRound,
      isLongBreak: _isLongBreak,
    );
  }

  int _getDurationForMode(PomodoroMode mode) {
    switch (mode) {
      case PomodoroMode.focus:
        return storageService.getPomodoroDuration() * 60;
      case PomodoroMode.breakMode:
        return (_isLongBreak ? storageService.getLongBreakDuration() : storageService.getShortBreakDuration()) * 60;
    }
  }

  void _resetToModeDuration(PomodoroMode mode) {
    _mode = mode;
    if (mode == PomodoroMode.focus) _isLongBreak = false;
    final duration = _getDurationForMode(mode);
    _totalSeconds = duration;
    _remainingSeconds = duration;
    _status = TimerStatus.initial;
    _persistState();
    notifyListeners();
  }

  // --- Public Timer Controls ---

  /// Starts countdown, disables duplicate starts, and clears any previous transition message.
  void startTimer() {
    if (isRunning) return;

    if (_remainingSeconds <= 0) {
      _remainingSeconds = _totalSeconds;
    }

    _transitionMessage = null;
    _status = TimerStatus.running;
    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    _persistState();

    _notificationService.scheduleTimerNotification(
      title: '${_mode.displayName} In Progress',
      body: _mode == PomodoroMode.focus
          ? 'Stay in the zone. You can do this!'
          : 'Relax and recharge your energy.',
      scheduledAfter: Duration(seconds: _remainingSeconds),
    );

    _startTicker();
    notifyListeners();
  }

  /// Temporarily stops countdown progression and preserves remaining time.
  void pauseTimer() {
    if (!isRunning) return;

    _stopTicker();
    if (_targetEndTime != null) {
      final difference = _targetEndTime!.difference(DateTime.now());
      _remainingSeconds = ((difference.inMilliseconds + 999) ~/ 1000).clamp(0, _totalSeconds);
      _targetEndTime = null;
    }

    _status = TimerStatus.paused;
    _persistState();
    _notificationService.cancelAllNotifications();
    notifyListeners();
  }

  /// Continues countdown from the exact remaining time without restarting.
  void resumeTimer() {
    if (!isPaused) return;

    _status = TimerStatus.running;
    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    _persistState();

    _notificationService.scheduleTimerNotification(
      title: '${_mode.displayName} Resumed',
      body: _mode == PomodoroMode.focus
          ? 'Continuing deep focus session.'
          : 'Continuing break interval.',
      scheduledAfter: Duration(seconds: _remainingSeconds),
    );

    _startTicker();
    notifyListeners();
  }

  /// Resets the active interval to its original duration, halts countdown, and clears transition notes.
  /// Never increments or touches completed session counts.
  void resetTimer() {
    _stopTicker();
    _targetEndTime = null;
    _transitionMessage = null;
    _notificationService.cancelAllNotifications();

    final duration = _getDurationForMode(_mode);
    _totalSeconds = duration;
    _remainingSeconds = duration;
    _status = TimerStatus.initial;

    _persistState();
    notifyListeners();
  }

  /// Switches between Focus and Break modes, updating duration and resetting countdown.
  void setMode(PomodoroMode mode) {
    if (_mode == mode && _status == TimerStatus.initial) return;

    _stopTicker();
    _targetEndTime = null;
    _transitionMessage = null;
    _notificationService.cancelAllNotifications();

    _mode = mode;
    _isLongBreak = false;
    final duration = _getDurationForMode(mode);
    _totalSeconds = duration;
    _remainingSeconds = duration;
    _status = TimerStatus.initial;

    _persistState();
    notifyListeners();
  }

  /// Resets today's completed focus sessions to 0 while preserving historical daily records.
  Future<void> resetProductivity() async {
    await storageService.resetTodaySessions();
    _completedSessions = 0;
    notifyListeners();
  }

  /// Clears visual transition message.
  void clearTransitionMessage() {
    _transitionMessage = null;
    notifyListeners();
  }

  /// Updates configured durations from settings.
  void updateDurations() {
    _totalRounds = storageService.getLongBreakInterval();
    if (_status == TimerStatus.initial) {
      _resetToModeDuration(_mode);
    }
    notifyListeners();
  }

  /// Refreshes dashboard settings that are stored outside the timer state.
  void notifySettingsChanged() => notifyListeners();

  // --- High-Precision Drift-Free Ticker & Automatic Transitions ---

  void _startTicker() {
    _stopTicker(); // Guarantees no duplicate concurrent tickers

    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _checkTick();
    });
  }

  void _checkTick() {
    if (_status != TimerStatus.running || _targetEndTime == null || _isTransitioning) {
      return;
    }

    final now = DateTime.now();
    final difference = _targetEndTime!.difference(now);

    if (difference <= Duration.zero) {
      _remainingSeconds = 0;
      _handleSessionCompletion();
    } else {
      final currentRemaining = (difference.inMilliseconds + 999) ~/ 1000;
      if (currentRemaining != _remainingSeconds) {
        _remainingSeconds = currentRemaining.clamp(0, _totalSeconds);
        _persistState();
        notifyListeners();
      }
    }
  }

  /// Executes atomic transition between Focus and Break modes.
  /// Guarantees transitions run strictly once with zero duplicate counting.
  void _handleSessionCompletion() {
    if (_status != TimerStatus.running || _isTransitioning) return;
    _isTransitioning = true;

    _stopTicker();
    _targetEndTime = null;

    final completedMode = _mode;
    _remainingSeconds = 0;
    _status = TimerStatus.completed;

    if (completedMode == PomodoroMode.focus) {
      _soundService.playFocusCompleteAlert();

      // 1. Focus Session Completed:
      // - Increment completed sessions count (persisted to storage)
      final wasLongBreakCycle = _currentRound == _totalRounds;
      _currentRound = (_currentRound % _totalRounds) + 1;
      _isLongBreak = wasLongBreakCycle;
      _transitionMessage = AppStrings.focusTransitionMessage;

      // Dispatches notification
      _notificationService.scheduleTimerNotification(
        title: AppStrings.focusCompletedHeadline,
        body: AppStrings.timeForShortBreak,
        scheduledAfter: Duration.zero,
      );

      // Automatically transition to Break Mode (05:00)
      _mode = PomodoroMode.breakMode;
      final breakDuration = (wasLongBreakCycle
          ? storageService.getLongBreakDuration()
          : storageService.getShortBreakDuration()) * 60;
      _totalSeconds = breakDuration;
      _remainingSeconds = breakDuration;
      _status = TimerStatus.initial;

      _isTransitioning = false;

      // Asynchronously update and persist session count safely
      storageService.recordCompletedFocusSession().then((updatedCount) {
        if (_disposed) return;
        storageService.recordFocusSession(durationSeconds: _totalFocusDuration());
        _completedSessions = updatedCount;
        _persistState();
        notifyListeners();
      });
    } else {
      _soundService.playBreakCompleteAlert();

      // 2. Break Session Completed:
      _transitionMessage = AppStrings.breakCompletedReadyToFocus;

      _notificationService.scheduleTimerNotification(
        title: 'Break completed!',
        body: 'Ready to focus?',
        scheduledAfter: Duration.zero,
      );

      // Automatically transition to Focus Mode (25:00)
      _mode = PomodoroMode.focus;
      _isLongBreak = false;
      final focusDuration = _getDurationForMode(PomodoroMode.focus);
      _totalSeconds = focusDuration;
      _remainingSeconds = focusDuration;
      _status = TimerStatus.initial;

      _isTransitioning = false;
      _persistState();
      notifyListeners();
    }
  }

  int _totalFocusDuration() => storageService.getPomodoroDuration() * 60;

  /// Test helper to simulate interval completion and verify automatic transitions.
  @visibleForTesting
  void simulateIntervalCompletionForTesting() {
    if (!isRunning) {
      startTimer();
    }
    _handleSessionCompletion();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    _midnightRefreshTimer?.cancel();
    _soundService.dispose();
    super.dispose();
  }
}
