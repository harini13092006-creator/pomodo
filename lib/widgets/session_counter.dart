import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../models/timer_model.dart';

/// Reusable session counter widget tracking round progress and completed sessions.
class SessionCounter extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final int completedSessions;
  final PomodoroMode mode;

  const SessionCounter({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.completedSessions,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Round Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalRounds, (index) {
            final int dotRound = index + 1;
            final bool isCurrent = dotRound == currentRound && mode == PomodoroMode.focus;
            final bool isPassed = dotRound < currentRound;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isCurrent
                    ? colors.primary
                    : (isPassed
                        ? colors.secondary
                        : colors.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        // Completed Sessions Counter Label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '${AppStrings.completedToday}: $completedSessions',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
