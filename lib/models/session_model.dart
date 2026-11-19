import 'timer_model.dart';

/// Represents a logged productivity or break session.
class SessionModel {
  final String id;
  final PomodoroMode mode;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final bool isCompleted;

  const SessionModel({
    required this.id,
    required this.mode,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    this.isCompleted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'isCompleted': isCompleted,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      mode: PomodoroMode.values.firstWhere(
        (m) => m.name == map['mode'],
        orElse: () => PomodoroMode.focus,
      ),
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      durationSeconds: map['durationSeconds'] as int,
      isCompleted: (map['isCompleted'] as bool?) ?? true,
    );
  }
}
