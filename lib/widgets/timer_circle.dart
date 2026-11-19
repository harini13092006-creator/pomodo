import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/utils/time_formatter.dart';
import '../models/timer_model.dart';

/// Large circular countdown timer with animated progress arc and mode badge.
class TimerCircle extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final PomodoroMode mode;
  final TimerStatus status;
  final double size;
  final String? statusSubtitle;

  const TimerCircle({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.mode,
    required this.status,
    this.size = 270,
    this.statusSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final double progress = totalSeconds > 0
        ? ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    final Color activeColor = mode == PomodoroMode.focus
        ? colors.primary
        : colors.tertiary;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: activeColor.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Custom Painter for Smooth Circular Track & Progress
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return CustomPaint(
                    size: Size(size - 32, size - 32),
                    painter: _TimerProgressPainter(
                      progress: value,
                      trackColor: colors.surfaceContainerHighest,
                      progressColor: activeColor,
                      strokeWidth: 12.0,
                    ),
                  );
                },
              ),
            ),

            // Inner Content: Mode Badge, MM:SS, Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mode Badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          mode.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Large Time Countdown (MM:SS)
                  Text(
                    TimeFormatter.formatTime(remainingSeconds),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      color: colors.onSurface,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtle status or transition label
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      statusSubtitle ??
                          (status.isRunning
                              ? (mode == PomodoroMode.focus ? 'Deep focus' : 'Resting')
                              : (status.isPaused ? 'Paused' : 'Ready')),
                      key: ValueKey<String>(statusSubtitle ?? '${status.name}_${mode.name}'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: statusSubtitle != null ? FontWeight.w600 : FontWeight.w500,
                        color: statusSubtitle != null ? activeColor : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _TimerProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Progress Arc Paint
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
