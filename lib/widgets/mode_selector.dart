import 'package:flutter/material.dart';
import '../models/timer_model.dart';

/// Minimalist capsule mode selector allowing seamless switching between Focus and Break modes.
class ModeSelector extends StatelessWidget {
  final PomodoroMode currentMode;
  final ValueChanged<PomodoroMode> onModeSelected;

  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth) / 2;

          return Stack(
            children: [
              // Animated Background Pill
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.fastOutSlowIn,
                alignment: currentMode == PomodoroMode.focus
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: itemWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: currentMode == PomodoroMode.focus
                        ? colors.primary
                        : colors.tertiary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: (currentMode == PomodoroMode.focus
                        ? colors.primary
                        : colors.tertiary)
                            .withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // Foreground Tappable Labels
              Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      title: 'Focus',
                      icon: Icons.lens_blur_rounded,
                      isSelected: currentMode == PomodoroMode.focus,
                      onTap: () => onModeSelected(PomodoroMode.focus),
                    ),
                  ),
                  Expanded(
                    child: _ModeTab(
                      title: 'Break',
                      icon: Icons.spa_outlined,
                      isSelected: currentMode == PomodoroMode.breakMode,
                      onTap: () => onModeSelected(PomodoroMode.breakMode),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
