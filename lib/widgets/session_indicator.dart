import 'package:flutter/material.dart';
import '../models/timer_model.dart';

/// Small visual session indicators showing completed vs remaining focus rounds in the cycle.
class SessionIndicator extends StatelessWidget {
  final int currentRound;
  final int totalRounds;
  final PomodoroMode mode;

  const SessionIndicator({
    super.key,
    required this.currentRound,
    required this.totalRounds,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalRounds, (index) {
            final int slot = index + 1;
            final bool isCompleted = slot < currentRound;
            final bool isCurrent = slot == currentRound && mode == PomodoroMode.focus;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isCurrent ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isCurrent
                    ? colors.primary
                    : (isCompleted
                        ? colors.secondary
                        : colors.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(5),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Cycle Round $currentRound of $totalRounds',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
