/// Centralized user-facing strings across the Pomodo application.
class AppStrings {
  AppStrings._();

  // App Identity & Greeting
  static const String appName = 'Pomodo';
  static const String greeting = 'Ready to focus?';
  static const String breakGreeting = 'Time to recharge';

  // Modes
  static const String modeFocus = 'Focus';
  static const String modeBreak = 'Break';

  // Controls
  static const String start = 'Start';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String reset = 'Reset';

  // Productivity & Session Statistics
  static const String todayCompleted = "Today's Focus";
  static const String dailyProgress = 'Daily Progress';
  static const String sessionsUnit = 'sessions';
  static const String dailyGoalTarget = 'Target: 4 sessions';
  static const String motivationalQuote = 'Small, steady steps grow into great achievements.';
  static const String breakQuote = 'Rest your mind, hydrate, and breathe deeply.';
  static const String completedToday = 'Completed Today';

  // Transition Messages
  static const String focusCompletedHeadline = 'Focus session completed!';
  static const String timeForShortBreak = 'Time for a short break!';
  static const String breakCompletedReadyToFocus = 'Break completed! Ready to focus?';
  static const String focusTransitionMessage = 'Focus session completed! Time for a short break!';

  // Reset Productivity Dialog
  static const String resetProductivityTitle = "Reset Today's Progress?";
  static const String resetProductivityMessage =
      'This will reset your completed focus sessions for today to 0. Historical records for previous days are safely preserved.';
  static const String resetAction = 'Reset';
  static const String cancelAction = 'Cancel';

  // Settings
  static const String settings = 'Settings';
  static const String timerSettings = 'Timer Settings';
  static const String pomodoroDuration = 'Focus Duration';
  static const String shortBreakDuration = 'Break Duration';
  static const String longBreakDuration = 'Extended Break Duration';
  static const String longBreakInterval = 'Break Interval';
  static const String preferences = 'Preferences';
  static const String soundEffects = 'Sound Effects';
  static const String soundEffectsSubtitle = 'Play audio chime when intervals end';
  static const String vibration = 'Vibration Alert';
  static const String vibrationSubtitle = 'Vibrate phone when intervals complete';
  static const String notifications = 'Notifications';
  static const String notificationsSubtitle = 'Alert when intervals complete in background';
  static const String minutes = 'min';

  // App Information & About
  static const String appVersion = '1.0.0 (Build 1)';
  static const String appInfoTitle = 'App Information';
  static const String aboutTitle = 'About Pomodo';
  static const String aboutDescription =
      'Pomodo is a minimal, distraction-free productivity timer designed to help you build calm, sustainable focus habits through structured work and rest intervals.';
  static const String appTagline = 'Calm, sustainable focus';
  static const String productivitySettings = 'Productivity Settings';
  static const String notificationSettings = 'Notification Settings';
}
