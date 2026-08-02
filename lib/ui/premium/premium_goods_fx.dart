import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// How long each board animation runs, in seconds.
abstract final class FxTiming {
  /// Matches the wave delay in `GameBloc._scheduleShelfWave`.
  static const double sell = 0.52;
  static const double slide = 0.34;
  static const double land = 0.26;
}

/// Animations the board painters run, keyed by good id.
///
/// The painters read these while a ticker advances them, so a running animation
/// never rebuilds the widget tree.
class GoodsFx {
  final Map<String, double> _slide = {};
  final Map<String, double> _land = {};

  /// Sale progress per box, so two boxes can sell side by side.
  final Map<int, double> _sell = {};

  bool get busy => _sell.isNotEmpty || _slide.isNotEmpty || _land.isNotEmpty;

  /// Progress of the sale on [shelfIndex]; 1 when that box is not selling.
  double sellOf(int shelfIndex) => _sell[shelfIndex] ?? 1;

  bool selling(int shelfIndex) => _sell.containsKey(shelfIndex);

  /// Progress of a good sliding forward out of the layer behind; 1 when settled.
  double slideOf(String id) => _slide[id] ?? 1;

  /// Progress of a good dropping into its place; 1 when settled.
  double landOf(String id) => _land[id] ?? 1;

  void startSell(int shelfIndex) => _sell[shelfIndex] = 0;

  void stopSell(int shelfIndex) => _sell.remove(shelfIndex);

  void slideForward(String id) {
    _land.remove(id);
    _slide[id] = 0;
  }

  void land(String id) {
    _slide.remove(id);
    _land[id] = 0;
  }

  void reset() {
    _slide.clear();
    _land.clear();
    _sell.clear();
  }

  void advance(double dt) {
    if (dt <= 0) return;
    _step(_sell, dt / FxTiming.sell);
    _step(_slide, dt / FxTiming.slide);
    _step(_land, dt / FxTiming.land);
  }

  static void _step<K>(Map<K, double> running, double step) {
    if (running.isEmpty) return;
    running.removeWhere((_, t) => t + step >= 1);
    for (final key in running.keys.toList(growable: false)) {
      running[key] = running[key]! + step;
    }
  }
}

/// Lets a painter repaint on its own, without a widget rebuild.
class FxRepaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Darkens and fades a good in one pass.
///
/// `darken` below 1 keeps the product readable but shaded, which is how a good
/// standing in the layer behind reads.
ColorFilter shadeFilter({double darken = 1, double opacity = 1}) {
  return ColorFilter.matrix(<double>[
    darken, 0, 0, 0, 0, //
    0, darken, 0, 0, 0, //
    0, 0, darken, 0, 0, //
    0, 0, 0, opacity, 0, //
  ]);
}

/// Shade on a good that stands in the layer behind the front row.
const double behindShade = 0.55;

/// Drop of the last stretch into place, then a short squash on contact.
///
/// [rise] is how far above its place the good still is, so it always lands on
/// the shelf instead of hanging in the air.
({double squash, double rise}) landPose(double t, double size) {
  final c = t.clamp(0.0, 1.0);
  if (c >= 1) return (squash: 0.0, rise: 0.0);
  if (c < 0.45) {
    final f = c / 0.45;
    // Gravity: the last bit of the drop speeds up.
    return (squash: 0.0, rise: size * 0.26 * (1 - f * f));
  }
  final f = (c - 0.45) / 0.55;
  return (squash: math.sin(math.pi * f) * (1 - f) * 0.18, rise: 0.0);
}

/// A sold good swells, then is lifted off the shelf and away.
///
/// The lift stays inside its own box, so goods are never seen flying across the
/// cupboard.
({double scale, double rise, double opacity}) sellPose(double t, double size) {
  final c = t.clamp(0.0, 1.0);
  if (c < 0.28) {
    final f = Curves.easeOutBack.transform(c / 0.28);
    return (scale: 1 + 0.22 * f, rise: size * 0.04 * f, opacity: 1.0);
  }
  final f = (c - 0.28) / 0.72;
  return (
    scale: 1.22 - 0.94 * Curves.easeInCubic.transform(f),
    rise: size * (0.04 + 0.26 * Curves.easeOutCubic.transform(f)),
    opacity: 1 - Curves.easeInQuad.transform(f),
  );
}

/// Ring, glow and sparks thrown off by a sale.
void paintSellBurst(Canvas canvas, Offset center, double radius, double t) {
  final c = t.clamp(0.0, 1.0);
  if (c <= 0 || c >= 1) return;
  final grow = Curves.easeOutCubic.transform(c);
  final fade = 1 - c;

  canvas.drawCircle(
    center,
    radius * (0.24 + grow * 0.62),
    Paint()
      ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.30 * fade * fade)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.28),
  );
  canvas.drawCircle(
    center,
    radius * (0.34 + grow * 0.98),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, radius * 0.11 * fade)
      ..color = const Color(0xFFFFE79A).withValues(alpha: 0.8 * fade),
  );

  const sparks = 9;
  for (var i = 0; i < sparks; i++) {
    final angle = i * (2 * math.pi / sparks) + grow * 0.7;
    final dist = radius * (0.3 + grow * 1.12);
    final p = center +
        Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.74);
    canvas.drawCircle(
      p,
      math.max(0.5, radius * 0.13 * fade),
      Paint()..color = const Color(0xFFFFD24A).withValues(alpha: fade),
    );
  }
}

/// Stamped straight onto the goods — no door, no cover.
void paintSoldStamp(Canvas canvas, Rect rect, double t) {
  final c = t.clamp(0.0, 1.0);
  if (c <= 0 || c >= 1) return;
  final bounce = Curves.elasticOut.transform(math.min(1.0, c / 0.7));
  final scale = 2.2 - 1.2 * bounce;
  final opacity = (c * 4).clamp(0.0, 1.0) * (c > 0.82 ? (1 - c) / 0.18 : 1.0);
  final lift = rect.height * 0.16 * Curves.easeOutCubic.transform(c);

  canvas.save();
  canvas.translate(rect.center.dx, rect.center.dy - lift);
  canvas.rotate(-0.18);
  canvas.scale(scale);

  final stampTp = TextPainter(
    text: TextSpan(
      text: 'SOLD',
      style: TextStyle(
        fontSize: math.min(rect.height * 0.42, 22.0),
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Color.fromRGBO(180, 30, 30, opacity),
        height: 1,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();

  const pad = 4.0;
  final stampRect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset.zero,
      width: stampTp.width + pad * 2,
      height: stampTp.height + pad,
    ),
    const Radius.circular(4),
  );
  canvas.drawRRect(
    stampRect,
    Paint()..color = Color.fromRGBO(180, 30, 30, 0.18 * opacity),
  );
  canvas.drawRRect(
    stampRect,
    Paint()
      ..color = Color.fromRGBO(180, 30, 30, 0.85 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2,
  );
  stampTp.paint(canvas, Offset(-stampTp.width / 2, -stampTp.height / 2));
  canvas.restore();
}

/// Keeps a picture of the parts of the board that never move, so only the goods
/// are redrawn while the board animates.
class StaticLayer {
  ui.Picture? _picture;
  Object? _key;

  void paint(Canvas canvas, Object key, void Function(Canvas) build) {
    if (_picture == null || _key != key) {
      final recorder = ui.PictureRecorder();
      build(Canvas(recorder));
      _picture?.dispose();
      _picture = recorder.endRecording();
      _key = key;
    }
    canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
    _key = null;
  }
}
