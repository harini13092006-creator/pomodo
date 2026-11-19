import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../models/timer_model.dart';

/// Productivity dashboard card showing completed sessions, daily progress bar, and motivational note.
class ProductivityCard extends StatelessWidget {
  final int completedSessions;
  final int targetSessions;
  final PomodoroMode mode;
  final VoidCallback? onResetPressed;

  const ProductivityCard({
    super.key,
    required this.completedSessions,
    this.targetSessions = 4,
    required this.mode,
    this.onResetPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final double progressRatio = targetSessions > 0
        ? (completedSessions / targetSessions).clamp(0.0, 1.0)
        : 0.0;
    final int progressPercent = (progressRatio * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Label, and Action & Percentage Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.todayCompleted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            '$completedSessions of $targetSessions ${AppStrings.sessionsUnit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onResetPressed != null) ...[
                    IconButton(
                      icon: const Icon(Icons.restart_alt_rounded, size: 20),
                      tooltip: "Reset Today's Progress",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      color: colors.onSurfaceVariant,
                      onPressed: onResetPressed,
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Percentage Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            progressRatio >= 1
                ? 'Daily goal reached — lovely work!'
                : '${(targetSessions - completedSessions).clamp(0, targetSessions)} sessions remaining today',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: progressRatio >= 1 ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          // Motivational Quote
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 16,
                color: colors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mode == PomodoroMode.focus
                      ? AppStrings.motivationalQuote
                      : AppStrings.breakQuote,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
