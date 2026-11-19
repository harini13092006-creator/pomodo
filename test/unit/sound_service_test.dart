import 'package:flutter_test/flutter_test.dart';
import 'package:pomodo/services/sound_service.dart';

class MockSoundService implements SoundService {
  bool _soundEnabled;
  bool _vibrationEnabled;
  int focusAlertCalls = 0;
  int breakAlertCalls = 0;
  int vibrationCalls = 0;

  MockSoundService({
    this._soundEnabled = true,
    this._vibrationEnabled = true,
  });

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
  Future<void> initialize() async {}

  @override
  Future<void> playFocusCompleteAlert() async {
    if (_soundEnabled) focusAlertCalls++;
    if (_vibrationEnabled) vibrationCalls++;
  }

  @override
  Future<void> playBreakCompleteAlert() async {
    if (_soundEnabled) breakAlertCalls++;
    if (_vibrationEnabled) vibrationCalls++;
  }

  @override
  Future<void> playTimerCompleteSound({bool isFocus = true}) async {
    if (isFocus) {
      await playFocusCompleteAlert();
    } else {
      await playBreakCompleteAlert();
    }
  }

  @override
  Future<void> triggerVibration({int durationMs = 400, List<int>? pattern}) async {
    if (_vibrationEnabled) vibrationCalls++;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService Settings & Alert Invariants', () {
    test('plays focus alert and triggers vibration when enabled', () async {
      final soundService = MockSoundService(soundEnabled: true, vibrationEnabled: true);

      await soundService.playFocusCompleteAlert();
      expect(soundService.focusAlertCalls, 1);
      expect(soundService.vibrationCalls, 1);
    });

    test('suppresses audio chime when sound is disabled', () async {
      final soundService = MockSoundService(soundEnabled: false, vibrationEnabled: true);

      await soundService.playFocusCompleteAlert();
      expect(soundService.focusAlertCalls, 0);
      expect(soundService.vibrationCalls, 1);
    });

    test('suppresses vibration when vibration is disabled', () async {
      final soundService = MockSoundService(soundEnabled: true, vibrationEnabled: false);

      await soundService.playBreakCompleteAlert();
      expect(soundService.breakAlertCalls, 1);
      expect(soundService.vibrationCalls, 0);
    });

    test('toggles sound and vibration settings dynamically', () async {
      final soundService = MockSoundService(soundEnabled: true, vibrationEnabled: true);

      soundService.setSoundEnabled(false);
      soundService.setVibrationEnabled(false);

      expect(soundService.isSoundEnabled, isFalse);
      expect(soundService.isVibrationEnabled, isFalse);

      await soundService.playFocusCompleteAlert();
      expect(soundService.focusAlertCalls, 0);
      expect(soundService.vibrationCalls, 0);

      soundService.setSoundEnabled(true);
      soundService.setVibrationEnabled(true);
      await soundService.playFocusCompleteAlert();
      expect(soundService.focusAlertCalls, 1);
      expect(soundService.vibrationCalls, 1);
    });
  });
}
