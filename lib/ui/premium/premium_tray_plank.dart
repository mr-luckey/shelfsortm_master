import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Wood tones of the belt plank, sampled from the tray reference.
abstract final class TrayPlankColors {
  static const surfaceHi = Color(0xFFF6D69C);
  static const surface = Color(0xFFEDC383);
  static const surfaceLo = Color(0xFFE3B26B);
  static const groove = Color(0xFFD3A05A);
  static const edgeHi = Color(0xFFDDA764);
  static const edgeLo = Color(0xFFC5883F);
  static const foot = Color(0xFFC98F45);
  static const footLo = Color(0xFFAE7331);
  static const grain = Color(0xFFD8AC70);
  static const shadow = Color(0xFF1B0F02);
}

/// Where goods stand on a plank: the top surface line and its usable width.
typedef PlankSurface = ({double surfaceY, double left, double width});

typedef _PlankGeom = ({
  double cx,
  double boardW,
  double frontL,
  double frontR,
  double backL,
  double backR,
  double frontY,
  double backY,
  double faceH,
  double edgeH,
  double footH,
  double bottom,
});

_PlankGeom _geom(Rect rect) {
  final h = rect.height;
  // A slim board: most of the cell is headroom for the goods on top.
  final boardW = rect.width * 0.94;
  final cx = rect.center.dx;
  final footH = h * 0.085;
  final edgeH = h * 0.06;
  final faceH = h * 0.075;
  final bottom = rect.bottom;
  final frontY = bottom - footH;
  final backInset = boardW * 0.035;
  final frontL = cx - boardW / 2;
  final frontR = cx + boardW / 2;
  return (
    cx: cx,
    boardW: boardW,
    frontL: frontL,
    frontR: frontR,
    backL: frontL + backInset,
    backR: frontR - backInset,
    frontY: frontY,
    backY: frontY - faceH,
    faceH: faceH,
    edgeH: edgeH,
    footH: footH,
    bottom: bottom,
  );
}

/// Surface a tray offers, without painting anything — used for hit testing.
PlankSurface trayPlankSurface(Rect rect) {
  final g = _geom(rect);
  return (
    surfaceY: g.backY + g.faceH * 0.72,
    left: g.frontL + g.boardW * 0.06,
    width: g.boardW * 0.88,
  );
}

/// Paints one thin wooden tray — a board on two feet, nothing enclosing it.
///
/// Goods are drawn afterwards standing on [PlankSurface.surfaceY], so the tray
/// stays a platform instead of a box.
PlankSurface paintTrayPlank(Canvas canvas, Rect rect) {
  final g = _geom(rect);
  final h = rect.height;

  // Contact shadow on the floor under the board.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(g.cx, g.bottom),
      width: g.boardW * 1.02,
      height: h * 0.075,
    ),
    Paint()
      ..color = TrayPlankColors.shadow.withValues(alpha: 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );

  // Two feet under the board.
  final footW = g.boardW * 0.1;
  for (final sign in const [-1.0, 1.0]) {
    final foot = Rect.fromLTWH(
      g.cx + sign * g.boardW * 0.34 - footW / 2,
      g.frontY - 1,
      footW,
      g.footH + 1,
    );
    canvas.drawRect(
      foot,
      Paint()
        ..shader = ui.Gradient.linear(
          foot.topCenter,
          foot.bottomCenter,
          const [TrayPlankColors.foot, TrayPlankColors.footLo],
        ),
    );
  }

  // Board thickness, seen from the front.
  final edge = Path()
    ..moveTo(g.frontL, g.frontY)
    ..lineTo(g.frontR, g.frontY)
    ..lineTo(g.frontR, g.frontY + g.edgeH)
    ..lineTo(g.frontL, g.frontY + g.edgeH)
    ..close();
  canvas.drawPath(
    edge,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(g.cx, g.frontY),
        Offset(g.cx, g.frontY + g.edgeH),
        const [TrayPlankColors.edgeHi, TrayPlankColors.edgeLo],
      ),
  );

  // Top surface, slightly narrower at the back so the board reads as 3D.
  final face = Path()
    ..moveTo(g.backL, g.backY)
    ..lineTo(g.backR, g.backY)
    ..lineTo(g.frontR, g.frontY)
    ..lineTo(g.frontL, g.frontY)
    ..close();
  canvas.drawPath(
    face,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(g.cx, g.backY),
        Offset(g.cx, g.frontY),
        const [
          TrayPlankColors.surfaceLo,
          TrayPlankColors.surface,
          TrayPlankColors.surfaceHi,
        ],
        const [0.0, 0.45, 1.0],
      ),
  );

  // Grain along the board plus the routed groove near its rim.
  final grain = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.6, h * 0.006)
    ..color = TrayPlankColors.grain.withValues(alpha: 0.55);
  for (var i = 1; i <= 2; i++) {
    final t = i / 3;
    final y = g.backY + (g.frontY - g.backY) * t;
    final inset = (g.backL - g.frontL) * (1 - t);
    canvas.drawLine(
      Offset(g.frontL + inset + g.boardW * 0.04, y),
      Offset(g.frontR - inset - g.boardW * 0.04, y),
      grain,
    );
  }
  canvas.drawLine(
    Offset(g.backL + g.boardW * 0.025, g.backY + g.faceH * 0.28),
    Offset(g.backR - g.boardW * 0.025, g.backY + g.faceH * 0.28),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, h * 0.007)
      ..color = TrayPlankColors.groove.withValues(alpha: 0.75),
  );

  // Thin highlight along the front lip.
  canvas.drawLine(
    Offset(g.frontL, g.frontY),
    Offset(g.frontR, g.frontY),
    Paint()
      ..strokeWidth = math.max(0.8, h * 0.008)
      ..color = TrayPlankColors.surfaceHi.withValues(alpha: 0.9),
  );

  return trayPlankSurface(rect);
}

/// Soft wash used to show a tray still has room while a good is carried.
void paintPlankFreeGlow(Canvas canvas, Rect rect, PlankSurface surface) {
  canvas.drawRect(
    Rect.fromLTWH(
      surface.left,
      surface.surfaceY - rect.height * 0.03,
      surface.width,
      rect.height * 0.06,
    ),
    Paint()
      ..color = const Color(0xFF66BB6A).withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
}
