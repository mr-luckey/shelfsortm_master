import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../widgets/emoji_assets.dart';

/// Product art decoded once and shared by the cupboard and the tray belt.
///
/// Faces are decoded down to the size the board actually draws them at, which
/// keeps both memory and per-frame scaling cost low.
class FaceImages extends ChangeNotifier {
  FaceImages._();

  static final FaceImages instance = FaceImages._();

  static const int decodeWidth = 192;

  final Map<String, ui.Image> _images = {};
  final Set<String> _requested = {};

  ui.Image? of(String type) => _images[type];

  int get length => _images.length;

  /// Loads [type] in the background if it is not decoded yet.
  void request(String type) {
    if (_images.containsKey(type)) return;
    if (!_requested.add(type)) return;
    _load(type);
  }

  Future<void> _load(String type) async {
    try {
      final data = await rootBundle.load(EmojiAssets.pathFor(type));
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: decodeWidth,
      );
      final frame = await codec.getNextFrame();
      _images[type] = frame.image;
      notifyListeners();
    } catch (_) {
      // Missing art — the place stays empty visually.
    }
  }
}
