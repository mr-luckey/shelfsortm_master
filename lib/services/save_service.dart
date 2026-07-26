import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_progress.dart';

class SaveService {
  static const _keyProgress = 'player_progress_v1';
  static const _keyMidLevel = 'mid_level_save_v1';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<PlayerProgress> loadProgress() async {
    final raw = _prefs?.getString(_keyProgress);
    if (raw == null) return PlayerProgress.initial();
    try {
      return PlayerProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return PlayerProgress.initial();
    }
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    await _prefs?.setString(_keyProgress, jsonEncode(progress.toJson()));
  }

  Future<void> saveMidLevel(Map<String, dynamic> state) async {
    await _prefs?.setString(_keyMidLevel, jsonEncode(state));
  }

  Future<Map<String, dynamic>?> loadMidLevel() async {
    final raw = _prefs?.getString(_keyMidLevel);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearMidLevel() async {
    await _prefs?.remove(_keyMidLevel);
  }
}
