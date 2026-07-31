import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/goods_sort_theme.dart';

/// Travel-map backdrop for level select (Goods Sort world tour vibe).
class MapBackground extends StatelessWidget {
  const MapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: GoodsSortTheme.mapGradient),
        ),
        Positioned.fill(child: CustomPaint(painter: _CloudPainter())),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GoodsSortTheme.mapGrass.withValues(alpha: 0.0),
                  GoodsSortTheme.mapGrass,
                  GoodsSortTheme.mapGrassDark,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    void cloud(double x, double y, double w) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: w * 0.38),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - w * 0.22, y + 4),
          width: w * 0.55,
          height: w * 0.28,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.25, y + 6),
          width: w * 0.5,
          height: w * 0.26,
        ),
        paint,
      );
    }

    cloud(size.width * 0.2, 80, 90);
    cloud(size.width * 0.75, 60, 110);
    cloud(size.width * 0.5, 140, 70);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Winding tan path strip behind level nodes.
class MapPathPainter extends CustomPainter {
  final List<Offset> centers;
  final Color color;

  MapPathPainter({required this.centers, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;

    final path = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i < centers.length; i++) {
      final prev = centers[i - 1];
      final cur = centers[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, mid.dy, mid.dx, mid.dy);
      path.quadraticBezierTo(cur.dx, mid.dy, cur.dx, cur.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 22
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant MapPathPainter old) =>
      old.centers != centers || old.color != color;
}

List<Offset> computeMapCenters({
  required int count,
  required double pathWidth,
  required double startLevel,
  double nodeSize = 58,
  double rowGap = 78,
}) {
  final centers = <Offset>[];
  for (var i = 0; i < count; i++) {
    final t = i / math.max(1, count - 1);
    final x =
        pathWidth / 2 +
        math.sin(t * math.pi * 2.2 + (startLevel / 100) * 0.7) *
            (pathWidth * 0.30);
    final y = i * rowGap + nodeSize / 2;
    centers.add(Offset(x, y));
  }
  return centers;
}
