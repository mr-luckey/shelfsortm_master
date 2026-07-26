import 'package:flutter/foundation.dart';

import '../services/audio_service.dart';

class SettingsProvider extends ChangeNotifier {
  final AudioService audio;

  SettingsProvider(this.audio);

  bool get sfx => audio.sfxEnabled;
  bool get music => audio.musicEnabled;
  bool get asmr => audio.asmrMode;
  bool get haptics => audio.hapticsEnabled;

  void setSfx(bool v) {
    audio.sfxEnabled = v;
    notifyListeners();
  }

  void setMusic(bool v) {
    audio.musicEnabled = v;
    notifyListeners();
  }

  void setAsmr(bool v) {
    audio.asmrMode = v;
    notifyListeners();
  }

  void setHaptics(bool v) {
    audio.hapticsEnabled = v;
    notifyListeners();
  }
}
