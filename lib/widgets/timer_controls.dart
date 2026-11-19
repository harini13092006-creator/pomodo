import 'package:flutter/material.dart';
import '../models/timer_model.dart';

/// Control bar supporting Start, Pause, Resume, and Reset actions with clean transitions.
class TimerControls extends StatelessWidget {
  final TimerStatus status;
  final PomodoroMode mode;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onReset;

  const TimerControls({
    super.key,
    required this.status,
    required this.mode,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isRunning = status.isRunning;
    final bool isPaused = status.isPaused;
    final bool isInitial = status.isInitial;

    final Color primaryActionColor = mode == PomodoroMode.focus
        ? colors.primary
        : colors.tertiary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset Button (Outlined Minimalist Pill/Circle)
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onReset,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isInitial ? colors.outlineVariant : colors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: isInitial ? colors.onSurfaceVariant : colors.onSurface,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Primary Action Button (Start / Pause / Resume)
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Material(
              color: primaryActionColor,
              borderRadius: BorderRadius.circular(28),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  if (isRunning) {
                    onPause();
                  } else if (isPaused) {
                    onResume();
                  } else {
                    onStart();
                  }
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryActionColor.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        key: ValueKey<String>('${status.name}_${mode.name}'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRunning
                                ? 'Pause'
                                : (isPaused ? 'Resume' : 'Start'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
