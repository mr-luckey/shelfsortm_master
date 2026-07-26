import 'package:flutter/services.dart';

/// Lightweight audio feedback without bundled wavs (system clicks + haptics).
/// ASMR mode amplifies haptic patterns. Swap for audioplayers assets later.
class AudioService {
  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool asmrMode = false;
  bool hapticsEnabled = true;

  Future<void> playPick() async {
    if (!sfxEnabled) return;
    await _haptic(light: true);
  }

  Future<void> playPlace() async {
    if (!sfxEnabled) return;
    await _haptic();
  }

  Future<void> playInvalid() async {
    if (!sfxEnabled) return;
    await _haptic(heavy: true);
  }

  Future<void> playShelfComplete() async {
    if (!sfxEnabled) return;
    await _haptic();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _haptic();
  }

  Future<void> playLevelComplete() async {
    if (!sfxEnabled) return;
    for (var i = 0; i < 3; i++) {
      await _haptic();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> playCombo() async {
    if (!sfxEnabled) return;
    await _haptic(light: true);
  }

  Future<void> playButton() async {
    if (!sfxEnabled) return;
    await _haptic(light: true);
  }

  Future<void> _haptic({bool light = false, bool heavy = false}) async {
    if (!hapticsEnabled && !asmrMode) return;
    if (heavy || asmrMode) {
      await HapticFeedback.mediumImpact();
    } else if (light) {
      await HapticFeedback.selectionClick();
    } else {
      await HapticFeedback.lightImpact();
    }
  }
}
