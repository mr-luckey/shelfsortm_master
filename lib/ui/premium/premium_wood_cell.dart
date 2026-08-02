import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Places a box or tray holds side by side.
const int spotsPerCell = 3;

/// Pixel colors sampled from the reference wood panel.
abstract final class WoodCellColors {
  static const frameHi = Color(0xFFE8C830);
  static const frameMid = Color(0xFFD4B018);
  static const frameAmber = Color(0xFFD0780C);
  static const frameRight = Color(0xFFE09A20);
  static const frameDeep = Color(0xFFA85800);
  static const bevelHi = Color(0xFFE8E060);
  static const rimEdge = Color(0xFF4A2804);
  // Cream interior so the emoji art reads clearly against the shelf.
  static const recess = Color(0xFF8A7550);
  static const wallTop = Color(0xFFBCA983);
  static const wallSide = Color(0xFFC6B491);
  static const wallRight = Color(0xFFEFE6D2);
  static const floor = Color(0xFFE3D6B8);
  static const back = Color(0xFFF9F3E4);
  static const backBright = Color(0xFFFFFDF6);
  static const backDark = Color(0xFFEEE4CE);
  static const backEdge = Color(0xFFDACBAA);
  static const innerShade = Color(0xFF9C8A66);
}

/// A box has three fixed places; a good never slides sideways because the
/// place next to it is empty.
double slotCenter(int slot, double cavityWidth) =>
    cavityWidth / spotsPerCell * (slot + 0.5);

/// Same insets as [paintWoodCell] cavity. Sides shared with a neighbour use
/// half the frame so the joint reads as one divider.
({double left, double width, double floorY}) cavityMetrics(
  Rect rect, {
  bool edgeL = true,
  bool edgeR = true,
  bool edgeB = true,
}) {
  final w = rect.width;
  final h = rect.height;
  final insetL = w * 0.109 * (edgeL ? 1 : 0.5);
  final insetR = w * 0.109 * (edgeR ? 1 : 0.5);
  final insetB = h * 0.146 * (edgeB ? 1 : 0.5);
  return (
    left: insetL,
    width: w - insetL - insetR,
    floorY: rect.height - insetB,
  );
}

/// Fills the shelf cavity height; the slot cap keeps neighbours from
/// colliding on wide boards.
double faceSize(Rect rect, double cavityWidth) {
  final slotW = cavityWidth / spotsPerCell;
  return math.min(slotW * 1.12, rect.height * 0.62);
}

void drawFace(
  Canvas canvas,
  ui.Image image,
  Rect dst,
  ColorFilter? filter,
) {
  final src = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  canvas.drawImageRect(
    image,
    src,
    dst,
    Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = filter,
  );
}

/// Grounds an item so it reads as standing on the shelf, not floating.
void paintContactShadow(Canvas canvas, double cx, double floorY, double s) {
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(cx, floorY - s * 0.03),
      width: s * 0.72,
      height: s * 0.17,
    ),
    Paint()
      ..color = const Color(0xFF6B5836).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
  );
}

void paintWoodCell(
  Canvas canvas,
  Rect rect, {
  Rect? board,
  bool edgeL = true,
  bool edgeT = true,
  bool edgeR = true,
  bool edgeB = true,
}) {
  // Frame shading spans the whole board so neighbours share one continuous
  // divider instead of two frame edges meeting.
  final panel = board ?? rect;
  final w = rect.width;
  final h = rect.height;
  final r = 0.0;

  // Proportions from reference frame (~644×425). Shared sides use half the
  // frame so two neighbours together form a single divider.
  final insetL = w * 0.109 * (edgeL ? 1 : 0.5);
  final insetR = w * 0.109 * (edgeR ? 1 : 0.5);
  final insetT = h * 0.129 * (edgeT ? 1 : 0.5);
  final insetB = h * 0.146 * (edgeB ? 1 : 0.5);
  final rim = math.min(w, h) * 0.055;
  final rimL = edgeL ? rim : rim * 0.5;
  final rimT = edgeT ? rim : rim * 0.5;
  final rimR = edgeR ? rim : rim * 0.5;
  final rimB = edgeB ? rim : rim * 0.5;

  final outer = RRect.fromRectAndRadius(rect, Radius.circular(r));
  final cavity = Rect.fromLTRB(
    rect.left + insetL,
    rect.top + insetT,
    rect.right - insetR,
    rect.bottom - insetB,
  );

  canvas.save();
  canvas.clipRRect(outer);

  // Outer gold frame body.
  canvas.drawRRect(
    outer,
    Paint()
      ..shader = ui.Gradient.linear(
        panel.topCenter,
        panel.bottomRight,
        const [
          WoodCellColors.frameHi,
          WoodCellColors.frameMid,
          WoodCellColors.frameAmber,
          WoodCellColors.frameRight,
        ],
        const [0.0, 0.28, 0.72, 1.0],
      ),
  );

  // Soft left/top highlight band on the rim.
  canvas.drawRRect(
    outer,
    Paint()
      ..shader = ui.Gradient.linear(
        panel.topLeft,
        Offset(
          panel.left + panel.width * 0.35,
          panel.top + panel.height * 0.45,
        ),
        [
          WoodCellColors.bevelHi.withValues(alpha: 0.55),
          WoodCellColors.bevelHi.withValues(alpha: 0.0),
        ],
      ),
  );

  // Inner bevel lip — only on the board's outer sides, so shared joints don't
  // show two parallel highlights.
  final lipPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, rim * 0.55)
    ..color = WoodCellColors.bevelHi.withValues(alpha: 0.7);
  final lipInset = rim * 0.85;
  final lipRect = rect.deflate(lipInset);
  if (edgeL) {
    canvas.drawLine(lipRect.topLeft, lipRect.bottomLeft, lipPaint);
  }
  if (edgeT) {
    canvas.drawLine(lipRect.topLeft, lipRect.topRight, lipPaint);
  }
  if (edgeR) {
    canvas.drawLine(lipRect.topRight, lipRect.bottomRight, lipPaint);
  }
  if (edgeB) {
    canvas.drawLine(lipRect.bottomLeft, lipRect.bottomRight, lipPaint);
  }

  // Depth walls (trapezoids from outer rim to cavity).
  final wallPaint = Paint()..style = PaintingStyle.fill;

  final topWall = Path()
    ..moveTo(rect.left + rimL, rect.top + rimT)
    ..lineTo(rect.right - rimR, rect.top + rimT)
    ..lineTo(cavity.right, cavity.top)
    ..lineTo(cavity.left, cavity.top)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.center.dx, rect.top + rimT),
    Offset(rect.center.dx, cavity.top),
    const [WoodCellColors.recess, WoodCellColors.wallTop, WoodCellColors.backEdge],
    const [0.0, 0.45, 1.0],
  );
  canvas.drawPath(topWall, wallPaint);

  final leftWall = Path()
    ..moveTo(rect.left + rimL, rect.top + rimT)
    ..lineTo(cavity.left, cavity.top)
    ..lineTo(cavity.left, cavity.bottom)
    ..lineTo(rect.left + rimL, rect.bottom - rimB)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.left + rimL, rect.center.dy),
    Offset(cavity.left, rect.center.dy),
    const [WoodCellColors.recess, WoodCellColors.wallSide, WoodCellColors.backEdge],
    const [0.0, 0.5, 1.0],
  );
  canvas.drawPath(leftWall, wallPaint);

  final rightWall = Path()
    ..moveTo(rect.right - rimR, rect.top + rimT)
    ..lineTo(cavity.right, cavity.top)
    ..lineTo(cavity.right, cavity.bottom)
    ..lineTo(rect.right - rimR, rect.bottom - rimB)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.right - rimR, rect.center.dy),
    Offset(cavity.right, rect.center.dy),
    const [WoodCellColors.frameDeep, WoodCellColors.wallRight, WoodCellColors.backDark],
    const [0.0, 0.45, 1.0],
  );
  canvas.drawPath(rightWall, wallPaint);

  final botWall = Path()
    ..moveTo(rect.left + rimL, rect.bottom - rimB)
    ..lineTo(cavity.left, cavity.bottom)
    ..lineTo(cavity.right, cavity.bottom)
    ..lineTo(rect.right - rimR, rect.bottom - rimB)
    ..close();
  wallPaint.shader = ui.Gradient.linear(
    Offset(rect.center.dx, cavity.bottom),
    Offset(rect.center.dx, rect.bottom - rimB),
    const [WoodCellColors.floor, WoodCellColors.frameAmber],
    const [0.0, 1.0],
  );
  canvas.drawPath(botWall, wallPaint);

  // Recessed wood back panel.
  canvas.drawRect(
    cavity,
    Paint()
      ..shader = ui.Gradient.radial(
        cavity.center,
        math.max(cavity.width, cavity.height) * 0.72,
        const [
          WoodCellColors.backBright,
          WoodCellColors.back,
          WoodCellColors.backDark,
          WoodCellColors.backEdge,
        ],
        const [0.0, 0.35, 0.75, 1.0],
      ),
  );

  // Vertical wood grain (deterministic per cell).
  final grain = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.6, w * 0.008)
    ..strokeCap = StrokeCap.round;
  final rng = math.Random(
    Object.hash(rect.left.round(), rect.top.round(), 0xC311),
  );
  final grainCount = math.max(8, (cavity.width / (w * 0.045)).round());
  for (var i = 0; i < grainCount; i++) {
    final t = (i + 0.5) / grainCount;
    final x = cavity.left + cavity.width * t + (rng.nextDouble() - 0.5) * w * 0.012;
    final dark = rng.nextBool();
    grain.color = (dark ? WoodCellColors.backEdge : WoodCellColors.backBright)
        .withValues(alpha: 0.10 + rng.nextDouble() * 0.10);
    final path = Path();
    final steps = 6;
    for (var s = 0; s <= steps; s++) {
      final yy = cavity.top + cavity.height * (s / steps);
      final xx = x + math.sin(s * 1.7 + i) * w * 0.004;
      if (s == 0) {
        path.moveTo(xx, yy);
      } else {
        path.lineTo(xx, yy);
      }
    }
    canvas.drawPath(path, grain);
  }

  // Soft top shadow onto the back panel.
  canvas.drawRect(
    Rect.fromLTWH(cavity.left, cavity.top, cavity.width, cavity.height * 0.32),
    Paint()
      ..shader = ui.Gradient.linear(
        cavity.topCenter,
        Offset(cavity.center.dx, cavity.top + cavity.height * 0.32),
        [
          WoodCellColors.innerShade.withValues(alpha: 0.34),
          WoodCellColors.innerShade.withValues(alpha: 0.0),
        ],
      ),
  );

  canvas.restore();

  // Rim edge — only around the board, never on a shared side.
  final rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.8, rim * 0.22)
    ..color = WoodCellColors.rimEdge;
  if (edgeL) {
    canvas.drawLine(rect.topLeft, rect.bottomLeft, rimPaint);
  }
  if (edgeT) {
    canvas.drawLine(rect.topLeft, rect.topRight, rimPaint);
  }
  if (edgeR) {
    canvas.drawLine(rect.topRight, rect.bottomRight, rimPaint);
  }
  if (edgeB) {
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, rimPaint);
  }
}
