import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

/// Enumeration of Pomodo timer modes.
enum PomodoroMode {
  focus,
  breakMode;

  String get displayName {
    switch (this) {
      case PomodoroMode.focus:
        return AppStrings.modeFocus;
      case PomodoroMode.breakMode:
        return AppStrings.modeBreak;
    }
  }

  Color get color {
    switch (this) {
      case PomodoroMode.focus:
        return AppColors.primary;
      case PomodoroMode.breakMode:
        return AppColors.accent;
    }
  }

  String get greeting {
    switch (this) {
      case PomodoroMode.focus:
        return AppStrings.greeting;
      case PomodoroMode.breakMode:
        return AppStrings.breakGreeting;
    }
  }

  String get quote {
    switch (this) {
      case PomodoroMode.focus:
        return AppStrings.motivationalQuote;
      case PomodoroMode.breakMode:
        return AppStrings.breakQuote;
    }
  }
}

/// Enumeration of current timer execution states.
enum TimerStatus {
  initial,
  running,
  paused,
  completed;

  bool get isInitial => this == TimerStatus.initial;
  bool get isRunning => this == TimerStatus.running;
  bool get isPaused => this == TimerStatus.paused;
  bool get isCompleted => this == TimerStatus.completed;
}

/// Immutable data model representing the timer snapshot.
class TimerModel {
  final PomodoroMode mode;
  final TimerStatus status;
  final int remainingSeconds;
  final int totalSeconds;
  final int currentRound;
  final int totalRounds;

  const TimerModel({
    required this.mode,
    required this.status,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.currentRound,
    required this.totalRounds,
  });

  /// Calculates progress ratio from 0.0 (started) to 1.0 (completed).
  double get progress {
    if (totalSeconds <= 0) return 0.0;
    final double elapsed = (totalSeconds - remainingSeconds).toDouble();
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  TimerModel copyWith({
    PomodoroMode? mode,
    TimerStatus? status,
    int? remainingSeconds,
    int? totalSeconds,
    int? currentRound,
    int? totalRounds,
  }) {
    return TimerModel(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
    );
  }
}
