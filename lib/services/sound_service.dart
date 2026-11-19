import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Abstract contract defining audio and haptic alerting operations.
abstract class SoundService {
  Future<void> initialize();
  Future<void> playFocusCompleteAlert();
  Future<void> playBreakCompleteAlert();
  Future<void> playTimerCompleteSound({bool isFocus = true});
  Future<void> triggerVibration({int durationMs = 400, List<int>? pattern});
  void setSoundEnabled(bool enabled);
  void setVibrationEnabled(bool enabled);
  bool get isSoundEnabled;
  bool get isVibrationEnabled;
  void dispose();
}

/// Production implementation of SoundService using audioplayers and vibration.
/// Manages player lifecycle, graceful fallbacks, and duplicate suppression.
class AppSoundService implements SoundService {
  final AudioPlayer _player;
  bool _soundEnabled;
  bool _vibrationEnabled;
  bool _isVibrating = false;

  AppSoundService({
    AudioPlayer? player,
    this._soundEnabled = true,
    this._vibrationEnabled = true,
  }) : _player = player ?? AudioPlayer();

  @override
  bool get isSoundEnabled => _soundEnabled;

  @override
  bool get isVibrationEnabled => _vibrationEnabled;

  @override
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  @override
  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  @override
  Future<void> initialize() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (e) {
      debugPrint('SoundService initialize error: $e');
    }
  }

  /// 1. FOCUS COMPLETION ALERT:
  /// Plays gentle harmonic meditation chime and triggers a short soft vibration.
  @override
  Future<void> playFocusCompleteAlert() async {
    await Future.wait([
      _playAssetSound('sounds/focus_complete.wav'),
      triggerVibration(durationMs: 400),
    ]);
  }

  /// 2. BREAK COMPLETION ALERT:
  /// Plays a soft uplifting marimba chime and triggers a double-pulse vibration.
  @override
  Future<void> playBreakCompleteAlert() async {
    await Future.wait([
      _playAssetSound('sounds/break_complete.wav'),
      triggerVibration(durationMs: 300, pattern: [0, 180, 120, 180]),
    ]);
  }

  /// Backward-compatible alias routing to appropriate alert.
  @override
  Future<void> playTimerCompleteSound({bool isFocus = true}) async {
    if (isFocus) {
      await playFocusCompleteAlert();
    } else {
      await playBreakCompleteAlert();
    }
  }

  /// Plays audio chime asset safely with error recovery and duplicate prevention.
  Future<void> _playAssetSound(String assetPath) async {
    if (!_soundEnabled) return;

    try {
      // Stop previous playback to release track and avoid overlap
      await _player.stop();
      await _player.play(
        AssetSource(assetPath),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('SoundService audio playback error ($assetPath): $e');
    }
  }

  /// Triggers device vibration safely with feature detection and duplicate suppression.
  @override
  Future<void> triggerVibration({int durationMs = 400, List<int>? pattern}) async {
    if (!_vibrationEnabled || _isVibrating) return;
    _isVibrating = true;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        if (pattern != null) {
          final hasCustom = await Vibration.hasCustomVibrationsSupport();
          if (hasCustom == true) {
            await Vibration.vibrate(pattern: pattern);
          } else {
            await Vibration.vibrate(duration: durationMs);
          }
        } else {
          await Vibration.vibrate(duration: durationMs);
        }
      }
    } catch (e) {
      debugPrint('SoundService vibration error: $e');
    } finally {
      // Release vibration lock after delay to prevent rapid duplicate triggers
      Future.delayed(const Duration(milliseconds: 600), () {
        _isVibrating = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      debugPrint('SoundService player dispose error: $e');
    }
  }
}
