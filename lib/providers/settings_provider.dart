import 'package:flutter/foundation.dart';

import '../bloc/audio_cubit.dart';

class SettingsProvider extends ChangeNotifier {
  final AudioCubit audio;

  SettingsProvider(this.audio) {
    audio.stream.listen((_) {
      if (hasListeners) notifyListeners();
    });
  }

  bool get sfx => audio.state.sfx;
  bool get music => audio.state.music;
  bool get asmr => audio.state.asmrMode;
  bool get haptics => audio.state.haptics;

  void setSfx(bool v) {
    audio.setSfx(v);
    notifyListeners();
  }

  void setMusic(bool v) {
    audio.setMusic(v);
    notifyListeners();
  }

  void setAsmr(bool v) {
    audio.setAsmrMode(v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    audio.setHaptics(v);
    notifyListeners();
  }
}
