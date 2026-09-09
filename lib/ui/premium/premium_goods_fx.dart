import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// How long each board animation runs, in seconds.
abstract final class FxTiming {
  /// Matches the wave delay in `GameBloc._scheduleShelfWave`.
  static const double sell = 0.72;
  static const double slide = 0.34;
  static const double land = 0.26;
}

/// Match-3 blast: the good pops, then breaks into falling pieces.
const double shatterAt = 0.18;

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

/// A matched good pops, then is gone so falling pieces can take over.
({double scale, double rise, double opacity}) sellPose(double t, double size) {
  final c = t.clamp(0.0, 1.0);
  if (c >= 1) return (scale: 0.0, rise: 0.0, opacity: 0.0);
  if (c < shatterAt) {
    final f = Curves.easeOutBack.transform(c / shatterAt);
    return (
      scale: 1 + 0.48 * f,
      rise: size * 0.12 * f,
      opacity: 1.0,
    );
  }
  return (scale: 1.48, rise: size * 0.12, opacity: 0.0);
}

double _blastHash(int seed, int i) {
  final n = (seed * 1103515245 + i * 12345) & 0x7fffffff;
  return (n % 10000) / 10000.0;
}

/// Flash, shockwave and sparks of a match-3 blast.
void paintSellBurst(Canvas canvas, Offset center, double radius, double t) {
  final c = t.clamp(0.0, 1.0);
  if (c <= 0 || c >= 1) return;

  final flash = (1 - (c / 0.28).clamp(0.0, 1.0));
  if (flash > 0) {
    canvas.drawCircle(
      center,
      radius * (0.55 + (1 - flash) * 1.15),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92 * flash)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55),
    );
    canvas.drawCircle(
      center,
      radius * (0.28 + (1 - flash) * 0.45),
      Paint()..color = const Color(0xFFFFF6C2).withValues(alpha: 0.95 * flash),
    );
  }

  for (final delay in const [0.0, 0.07, 0.14]) {
    final rt = ((c - delay) / 0.48).clamp(0.0, 1.0);
    if (rt <= 0 || rt >= 1) continue;
    final grow = Curves.easeOutCubic.transform(rt);
    final fade = 1 - rt;
    canvas.drawCircle(
      center,
      radius * (0.35 + grow * 2.55),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, radius * 0.22 * fade)
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.95 * fade),
    );
  }

  const sparks = 22;
  for (var i = 0; i < sparks; i++) {
    final h = _blastHash(i * 17, 3);
    final angle = i * (2 * math.pi / sparks) + c * (0.9 + h);
    final dist = radius * (0.2 + Curves.easeOutCubic.transform(c) * (1.55 + h));
    final p = center +
        Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.82);
    final fade = (1 - c).clamp(0.0, 1.0);
    canvas.drawCircle(
      p,
      math.max(0.7, radius * 0.11 * fade * (0.7 + h)),
      Paint()..color = const Color(0xFFFFD24A).withValues(alpha: fade),
    );
    final tail = center +
        Offset(
          math.cos(angle) * dist * 0.62,
          math.sin(angle) * dist * 0.62 * 0.82,
        );
    canvas.drawLine(
      tail,
      p,
      Paint()
        ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.75 * fade)
        ..strokeWidth = math.max(1.0, radius * 0.045)
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Small pieces of the matched good flying out, then falling.
void paintFallingPieces(
  Canvas canvas,
  Rect from,
  double t, {
  ui.Image? image,
  int seed = 0,
}) {
  final c = t.clamp(0.0, 1.0);
  if (c < shatterAt || c >= 1) return;
  final u = ((c - shatterAt) / (1 - shatterAt)).clamp(0.0, 1.0);
  final origin = from.center;
  final size = from.shortestSide;
  if (size <= 0) return;

  const cols = 4;
  const rows = 4;
  final count = cols * rows;
  final fade = (1 - Curves.easeInQuad.transform(u)).clamp(0.0, 1.0);
  if (fade <= 0.02) return;

  final imgPaint = Paint()
    ..filterQuality = FilterQuality.low
    ..colorFilter = ColorFilter.mode(
      Color.fromRGBO(255, 255, 255, fade),
      BlendMode.modulate,
    );

  for (var i = 0; i < count; i++) {
    final h = _blastHash(seed, i);
    final gx = i % cols;
    final gy = i ~/ cols;
    final angle = (i / count) * math.pi * 2 + (h - 0.5) * 0.85;
    final speed = size * (2.6 + h * 2.8);
    final vx = math.cos(angle) * speed;
    final vy = math.sin(angle) * speed * 0.62 - size * 3.1;
    final g = size * 16.5;
    final x = origin.dx + vx * u;
    final y = origin.dy + vy * u + 0.5 * g * u * u;
    final rot = (h - 0.5) * 12.5 * u;
    final pw = from.width / cols * (0.82 + h * 0.3);
    final ph = from.height / rows * (0.82 + (1 - h) * 0.3);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    canvas.scale(1.05 - 0.35 * u);
    final dest = Rect.fromCenter(center: Offset.zero, width: pw, height: ph);
    if (image != null) {
      final src = Rect.fromLTWH(
        image.width * gx / cols,
        image.height * gy / rows,
        image.width / cols,
        image.height / rows,
      );
      canvas.drawImageRect(image, src, dest, imgPaint);
    } else {
      canvas.drawRect(
        dest,
        Paint()..color = const Color(0xFFFFE082).withValues(alpha: fade),
      );
    }
    canvas.restore();
  }

  const chips = 10;
  const chipColors = <Color>[
    Color(0xFFFFF8E1),
    Color(0xFFFFE082),
    Color(0xFFFFD54F),
    Color(0xFFFF9800),
  ];
  for (var i = 0; i < chips; i++) {
    final h = _blastHash(seed ^ 0x9E37, i + 31);
    final angle = (i / chips) * math.pi * 2 + h * 1.4;
    final speed = size * (1.8 + h * 3.2);
    final vx = math.cos(angle) * speed;
    final vy = math.sin(angle) * speed * 0.7 - size * 2.4;
    final g = size * 15.0;
    final x = origin.dx + vx * u;
    final y = origin.dy + vy * u + 0.5 * g * u * u;
    final rot = (h - 0.5) * 14 * u;
    final chip = size * (0.08 + h * 0.1) * (1 - 0.25 * u);
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: chip * 1.4, height: chip),
        const Radius.circular(1.2),
      ),
      Paint()..color = chipColors[i % chipColors.length].withValues(alpha: fade),
    );
    canvas.restore();
  }
}

/// Blast flash plus the matched good breaking into falling pieces.
void paintMatchBlast(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double t,
  Rect? from,
  ui.Image? image,
  int seed = 0,
}) {
  paintSellBurst(canvas, center, radius, t);
  paintFallingPieces(
    canvas,
    from ?? Rect.fromCircle(center: center, radius: radius * 0.7),
    t,
    image: image,
    seed: seed,
  );
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
