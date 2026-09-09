import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioState extends Equatable {
  final bool sfx;
  final bool music;
  final bool haptics;
  final bool asmrMode;
  final bool ready;

  const AudioState({
    this.sfx = true,
    this.music = true,
    this.haptics = true,
    this.asmrMode = true,
    this.ready = false,
  });

  AudioState copyWith({
    bool? sfx,
    bool? music,
    bool? haptics,
    bool? asmrMode,
    bool? ready,
  }) {
    return AudioState(
      sfx: sfx ?? this.sfx,
      music: music ?? this.music,
      haptics: haptics ?? this.haptics,
      asmrMode: asmrMode ?? this.asmrMode,
      ready: ready ?? this.ready,
    );
  }

  @override
  List<Object?> get props => [sfx, music, haptics, asmrMode, ready];
}

/// App-wide audio via BLoC.
///
/// All SFX/voice WAVs are loaded into RAM once ([BytesSource]), then played
/// from memory — no asset I/O per tap. That removes the delay/miss bugs from
/// Android SoundPool seek+resume.
class AudioCubit extends Cubit<AudioState> {
  AudioCubit() : super(const AudioState());

  static const praiseLabels = [
    'Nice!',
    'Great!',
    'Awesome!',
    'Sweet!',
    'Perfect!',
    'Amazing!',
  ];

  static const _root = 'audio';
  static const _bgmAsset = '$_root/bgm_calm_loop.wav';

  /// One voice clip per praise label (Sweet has no dedicated WAV — uses great
  /// with a bright whoosh accent so it still feels distinct).
  static const _praiseFiles = [
    'voice_nice.wav',
    'voice_great.wav',
    'voice_awesome.wav',
    'voice_great.wav', // Sweet!
    'voice_perfect.wav',
    'voice_amazing.wav',
  ];

  final AudioPlayer _music = AudioPlayer();
  final Map<String, Uint8List> _bytes = {};

  late List<_SfxSlot> _tap;
  late List<_SfxSlot> _pick;
  late List<_SfxSlot> _place;
  late List<_SfxSlot> _match;
  late List<_SfxSlot> _combo;
  late List<_SfxSlot> _invalid;
  late List<_SfxSlot> _win;
  late List<_SfxSlot> _whoosh;
  late List<_SfxSlot> _voice;
  final List<AudioPlayer> _owned = [];

  int _tapI = 0;
  int _pickI = 0;
  int _placeI = 0;
  int _matchI = 0;
  int _comboI = 0;
  int _invalidI = 0;
  int _winI = 0;
  int _whooshI = 0;
  int _voiceI = 0;
  int _praiseI = 0;
  bool _musicBusy = false;

  Future<void> init() async {
    if (state.ready) return;

    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
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

    const files = <String>[
      'sfx_tap.wav',
      'sfx_pick.wav',
      'sfx_place.wav',
      'sfx_match.wav',
      'sfx_combo.wav',
      'sfx_invalid.wav',
      'sfx_win.wav',
      'sfx_whoosh.wav',
      'voice_nice.wav',
      'voice_great.wav',
      'voice_awesome.wav',
      'voice_perfect.wav',
      'voice_amazing.wav',
    ];
    for (final f in files) {
      try {
        final data = await rootBundle.load('assets/$_root/$f');
        _bytes[f] = data.buffer.asUint8List();
      } catch (_) {}
    }

    _tap = await _pool('sfx_tap.wav', 4, 0.85);
    _pick = await _pool('sfx_pick.wav', 4, 0.9);
    _place = await _pool('sfx_place.wav', 5, 1.0);
    _match = await _pool('sfx_match.wav', 3, 1.0);
    _combo = await _pool('sfx_combo.wav', 3, 1.0);
    _invalid = await _pool('sfx_invalid.wav', 2, 0.85);
    _win = await _pool('sfx_win.wav', 2, 1.0);
    _whoosh = await _pool('sfx_whoosh.wav', 2, 0.9);
    _voice = await _pool(null, 3, 0.7); // source set per praise

    try {
      await _music.setPlayerMode(PlayerMode.mediaPlayer);
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.setVolume(0.16);
      _owned.add(_music);
    } catch (_) {}

    emit(state.copyWith(ready: true));
  }

  Future<List<_SfxSlot>> _pool(String? file, int count, double volume) async {
    final out = <_SfxSlot>[];
    final bytes = file == null ? null : _bytes[file];
    for (var i = 0; i < count; i++) {
      final p = AudioPlayer();
      _owned.add(p);
      try {
        // mediaPlayer + RAM bytes: seek/resume works; SoundPool does not.
        await p.setPlayerMode(PlayerMode.mediaPlayer);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(volume);
        if (bytes != null) {
          await p.setSource(BytesSource(bytes));
        }
      } catch (_) {}
      out.add(_SfxSlot(player: p, file: file, volume: volume));
    }
    return out;
  }

  // ── settings ────────────────────────────────────────────────────────────

  void setSfx(bool enabled) => emit(state.copyWith(sfx: enabled));

  void setMusic(bool enabled) {
    emit(state.copyWith(music: enabled));
    if (enabled) {
      startMusic(force: true);
    } else {
      pauseMusic();
    }
  }

  void setHaptics(bool enabled) => emit(state.copyWith(haptics: enabled));

  void setAsmrMode(bool enabled) => emit(state.copyWith(asmrMode: enabled));

  // ── music ───────────────────────────────────────────────────────────────

  void startMusic({bool force = false}) {
    if (!state.music || _musicBusy) return;
    _musicBusy = true;
    () async {
      try {
        if (!force) {
          final s = _music.state;
          if (s == PlayerState.playing) return;
          if (s == PlayerState.paused) {
            await _music.resume();
            return;
          }
        }
        await _music.stop();
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(0.16);
        await _music.play(AssetSource(_bgmAsset));
      } catch (_) {
      } finally {
        _musicBusy = false;
      }
    }();
  }

  void pauseMusic() {
    () async {
      try {
        await _music.pause();
      } catch (_) {}
    }();
  }

  void stopMusic() {
    () async {
      try {
        await _music.stop();
      } catch (_) {}
    }();
  }

  // ── sfx (instant) ───────────────────────────────────────────────────────

  void playButton() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_tap, _tapI++);
  }

  void playPick() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_pick, _pickI++);
  }

  void playPlace() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_place, _placeI++);
  }

  void playInvalid() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_invalid, _invalidI++);
  }

  void playShelfComplete() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_match, _matchI++);
  }

  void playCombo() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_combo, _comboI++);
  }

  void playLevelComplete() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_win, _winI++);
    startMusic();
  }

  void playWhoosh() {
    if (!state.sfx) return;
    _softHaptic();
    _fire(_whoosh, _whooshI++);
  }

  /// Instant praise label + voice from RAM. Never blocks UI.
  String playPraise() {
    final i = _praiseI % _praiseFiles.length;
    _praiseI++;
    final label = praiseLabels[i];
    if (!state.sfx) return label;
    _softHaptic();

    final file = _praiseFiles[i];
    final bytes = _bytes[file];
    if (bytes == null) return label;

    final slot = _voice[_voiceI++ % _voice.length];
    () async {
      try {
        final p = slot.player;
        await p.stop();
        await p.setSource(BytesSource(bytes));
        await p.setVolume(slot.volume);
        await p.resume();
      } catch (_) {
        try {
          await slot.player.play(BytesSource(bytes), volume: slot.volume);
        } catch (_) {}
      }
    }();

    // Sweet gets a bright accent so it isn't a silent / identical clone.
    if (label == 'Sweet!') {
      _fire(_whoosh, _whooshI++);
    }
    return label;
  }

  /// Play preloaded RAM clip on the next free pool player — no asset reload.
  void _fire(List<_SfxSlot> pool, int index) {
    if (pool.isEmpty) return;
    final slot = pool[index % pool.length];
    final file = slot.file;
    final bytes = file == null ? null : _bytes[file];
    if (bytes == null) return;

    final p = slot.player;
    // Fire-and-forget. Prefer stop→seek→resume on warm mediaPlayer.
    () async {
      try {
        final st = p.state;
        if (st == PlayerState.playing || st == PlayerState.completed) {
          await p.stop();
        }
        await p.seek(Duration.zero);
        await p.setVolume(slot.volume);
        await p.resume();
      } catch (_) {
        try {
          await p.play(BytesSource(bytes), volume: slot.volume);
        } catch (_) {}
      }
    }();
  }

  void _softHaptic() {
    if (!state.haptics) return;
    HapticFeedback.selectionClick();
  }

  @override
  Future<void> close() async {
    for (final p in _owned) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    _owned.clear();
    return super.close();
  }
}

class _SfxSlot {
  final AudioPlayer player;
  final String? file;
  final double volume;

  const _SfxSlot({
    required this.player,
    required this.file,
    required this.volume,
  });
}
