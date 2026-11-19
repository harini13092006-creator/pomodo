import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/timer_model.dart';
import '../providers/timer_provider.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/mode_selector.dart';
import '../widgets/productivity_card.dart';
import '../widgets/session_indicator.dart';
import '../widgets/timer_circle.dart';
import '../widgets/timer_controls.dart';
import 'settings_screen.dart';

/// Primary Home Screen delivering a calm, forest-inspired Pomodoro productivity dashboard.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showResetConfirmationDialog(BuildContext context, TimerProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.resetProductivityTitle,
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppStrings.resetProductivityMessage,
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancelAction,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AppStrings.resetAction,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.resetProductivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // Responsive sizing calculation for diverse Android screen formats
    final double timerSize = (screenHeight * 0.32).clamp(240.0, 290.0);
    final double verticalSpacing = (screenHeight * 0.022).clamp(12.0, 22.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header (Logo, App Name, Greeting, Settings Action)
              AppHeader(
                mode: timerProvider.mode,
                onSettingsPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              SizedBox(height: verticalSpacing),

              // 2. Mode Selector (Focus / Break)
              ModeSelector(
                currentMode: timerProvider.mode,
                onModeSelected: (mode) => timerProvider.setMode(mode),
              ),
              SizedBox(height: verticalSpacing),

              // Visual Transition Banner (Clear transition message)
              if (timerProvider.transitionMessage != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (timerProvider.mode == PomodoroMode.breakMode
                            ? AppColors.accent
                            : AppColors.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (timerProvider.mode == PomodoroMode.breakMode
                              ? AppColors.accent
                              : AppColors.primary)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        timerProvider.mode == PomodoroMode.breakMode
                            ? Icons.coffee_rounded
                            : Icons.check_circle_rounded,
                        size: 16,
                        color: timerProvider.mode == PomodoroMode.breakMode
                            ? AppColors.accent
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          timerProvider.transitionMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: timerProvider.mode == PomodoroMode.breakMode
                                ? AppColors.textPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: verticalSpacing * 0.4),
              ],

              // 3. Main Circular Timer with MM:SS Countdown, Progress & Status
              TimerCircle(
                size: timerSize,
                remainingSeconds: timerProvider.remainingSeconds,
                totalSeconds: timerProvider.totalSeconds,
                mode: timerProvider.mode,
                status: timerProvider.status,
                statusSubtitle: timerProvider.transitionMessage,
              ),
              SizedBox(height: verticalSpacing),

              // 4. Session Indicator (Small Visual Round Indicators)
              SessionIndicator(
                currentRound: timerProvider.currentRound,
                totalRounds: timerProvider.totalRounds,
                mode: timerProvider.mode,
              ),
              SizedBox(height: verticalSpacing * 1.2),

              // 5. Timer Controls (Start, Pause, Resume, Reset)
              TimerControls(
                status: timerProvider.status,
                mode: timerProvider.mode,
                onStart: timerProvider.startTimer,
                onPause: timerProvider.pauseTimer,
                onResume: timerProvider.resumeTimer,
                onReset: timerProvider.resetTimer,
              ),
              SizedBox(height: verticalSpacing * 1.3),

              // 6. Productivity Counter Card (Today's Completed, Daily Progress, Motivation)
              ProductivityCard(
                completedSessions: timerProvider.completedSessions,
              targetSessions: context.read<StorageService>().getDailyGoal(),
                mode: timerProvider.mode,
                onResetPressed: () => _showResetConfirmationDialog(context, timerProvider),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
