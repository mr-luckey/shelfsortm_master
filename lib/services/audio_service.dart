import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Original-style feedback: system click + haptics (instant).
/// Short put/match clips + quiet BGM on top.
class AudioService {
  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool asmrMode = false;
  bool hapticsEnabled = true;

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();

  final List<AudioPlayer> _taps = [AudioPlayer(), AudioPlayer(), AudioPlayer()];
  final List<AudioPlayer> _places = [AudioPlayer(), AudioPlayer()];
  int _tapI = 0;
  int _placeI = 0;

  bool _ready = false;
  bool _musicBusy = false;
  bool _poolsReady = false;
  int _praiseIndex = 0;

  static const _root = 'audio';

  static const praiseLabels = [
    'Nice!',
    'Great!',
    'Awesome!',
    'Sweet!',
    'Perfect!',
    'Amazing!',
  ];

  static const _praises = [
    'voice_nice.wav',
    'voice_great.wav',
    'voice_awesome.wav',
    'voice_nice.wav', // Sweet! reuses soft nice stinger
    'voice_perfect.wav',
    'voice_amazing.wav',
  ];

  Future<void> init() async {
    if (_ready) return;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {},
          ),
        ),
      );
    } catch (_) {}

    try {
      await _music.setPlayerMode(PlayerMode.mediaPlayer);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.18);

      await _voice.setPlayerMode(PlayerMode.lowLatency);
      await _voice.setReleaseMode(ReleaseMode.stop);
      await _voice.setVolume(0.55);

      await _sfx.setPlayerMode(PlayerMode.lowLatency);
      await _sfx.setReleaseMode(ReleaseMode.stop);
      await _sfx.setVolume(0.65);

      for (final t in _taps) {
        await t.setPlayerMode(PlayerMode.lowLatency);
        await t.setReleaseMode(ReleaseMode.stop);
        await t.setVolume(0.7);
        await t.setSource(AssetSource('$_root/sfx_tap.wav'));
      }
      for (final p in _places) {
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(0.85);
        await p.setSource(AssetSource('$_root/sfx_place.wav'));
      }
      _poolsReady = true;

      _music.onPlayerComplete.listen((_) {
        if (musicEnabled && !_musicBusy) {
          startMusic(force: true);
        }
      });
    } catch (_) {}

    _ready = true;
  }

  Future<void> startMusic({bool force = false}) async {
    if (!musicEnabled) return;
    if (_musicBusy) return;
    _musicBusy = true;
    try {
      if (!force) {
        final state = _music.state;
        if (state == PlayerState.playing) return;
        if (state == PlayerState.paused) {
          await _music.resume();
          return;
        }
      }
      await _music.stop();
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.18);
      await _music.play(AssetSource('$_root/bgm_calm_loop.wav'));
    } catch (_) {
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music.stop();
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool v) async {
    musicEnabled = v;
    if (v) {
      await startMusic(force: true);
    } else {
      await pauseMusic();
    }
  }

  Future<void> playPick() async {}

  Future<void> playPlace() async {
    if (!sfxEnabled) return;
    SystemSound.play(SystemSoundType.click);
    _haptic();
    _playPool(_places, _placeI++, 'sfx_place.wav');
  }

  Future<void> playInvalid() async {
    if (!sfxEnabled) return;
    SystemSound.play(SystemSoundType.alert);
    _haptic(heavy: true);
    _playOne('sfx_invalid.wav');
  }

  Future<void> playShelfComplete() async {
    if (!sfxEnabled) return;
    SystemSound.play(SystemSoundType.click);
    _haptic();
    _playOne('sfx_match.wav');
    Future<void>.delayed(const Duration(milliseconds: 80), () => _haptic());
  }

  Future<void> playLevelComplete() async {
    if (!sfxEnabled) return;
    _playOne('sfx_win.wav');
    for (var i = 0; i < 3; i++) {
      _haptic();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    await startMusic();
  }

  Future<void> playCombo() async {
    if (!sfxEnabled) return;
    SystemSound.play(SystemSoundType.click);
    _haptic(light: true);
    _playOne('sfx_combo.wav');
  }

  /// Instant UI: system click + original selection haptic + short tap clip.
  Future<void> playButton() async {
    if (!sfxEnabled) return;
    SystemSound.play(SystemSoundType.click);
    _haptic(light: true);
    _playPool(_taps, _tapI++, 'sfx_tap.wav');
  }

  Future<void> playWhoosh() async {
    if (!sfxEnabled) return;
    SystemSound.play(SystemSoundType.click);
    _haptic(light: true);
  }

  Future<String> playPraise() async {
    final i = _praiseIndex % _praises.length;
    _praiseIndex++;
    final label = praiseLabels[i];
    if (sfxEnabled) {
      () async {
        try {
          await _voice.stop();
          await _voice.play(AssetSource('$_root/${_praises[i]}'));
        } catch (_) {}
      }();
    }
    _haptic(light: true);
    return label;
  }

  void _playPool(List<AudioPlayer> pool, int index, String file) {
    final p = pool[index % pool.length];
    if (_poolsReady) {
      p.seek(Duration.zero).then((_) => p.resume()).catchError((_) {
        p.play(AssetSource('$_root/$file'));
      });
    } else {
      p.play(AssetSource('$_root/$file'));
    }
  }

  void _playOne(String file) {
    () async {
      try {
        await _sfx.stop();
        await _sfx.play(AssetSource('$_root/$file'));
      } catch (_) {}
    }();
  }

  void _haptic({bool light = false, bool heavy = false}) {
    if (!hapticsEnabled && !asmrMode) return;
    if (heavy || asmrMode) {
      HapticFeedback.mediumImpact();
    } else if (light) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> dispose() async {
    await _music.dispose();
    await _voice.dispose();
    await _sfx.dispose();
    for (final t in _taps) {
      await t.dispose();
    }
    for (final p in _places) {
      await p.dispose();
    }
  }
}
