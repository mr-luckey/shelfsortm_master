import 'package:flutter/material.dart';

/// Paints an ornate wooden cupboard for ANY rows×cols (up to 5×7).
/// Grid matches gameplay exactly — no stretched PNG mismatch.
class ModularCupboardPainter extends CustomPainter {
  final int rows;
  final int cols;

  const ModularCupboardPainter({required this.rows, required this.cols});

  static const insetL = 0.07;
  static const insetR = 0.07;
  static const insetT = 0.06;
  static const insetB = 0.14;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.92),
      const Radius.circular(14),
    );

    canvas.drawRRect(
      outer.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final bodyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.90);
    final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(14));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8C49A),
            Color(0xFFD4A574),
            Color(0xFFB88855),
            Color(0xFF9A6B3C),
          ],
        ).createShader(bodyRect),
    );

    final grain = Paint()
      ..color = const Color(0xFF8B5A2B).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 0; i < 18; i++) {
      final x = size.width * (0.05 + i * 0.05);
      canvas.drawLine(
        Offset(x, 4),
        Offset(x * 0.98, bodyRect.bottom - 4),
        grain,
      );
    }

    final grid = Rect.fromLTRB(
      size.width * insetL,
      size.height * insetT,
      size.width * (1 - insetR),
      size.height * (1 - insetB),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(grid.inflate(3), const Radius.circular(6)),
      Paint()..color = const Color(0xFF5C3A1A).withValues(alpha: 0.55),
    );

    // Cubby interiors are Image.asset cells (cubby_unit.png) — only frame here.
    _flourish(canvas, Offset(grid.left + 8, grid.top + 8), 0);
    _flourish(canvas, Offset(grid.right - 8, grid.top + 8), 1);
    _flourish(canvas, Offset(grid.left + 8, grid.bottom - 8), 2);
    _flourish(canvas, Offset(grid.right - 8, grid.bottom - 8), 3);
    _paintBase(canvas, size);
  }

  void _flourish(Canvas canvas, Offset at, int corner) {
    final paint = Paint()
      ..color = const Color(0xFF6B3F1A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path();
    const s = 10.0;
    switch (corner) {
      case 0:
        path
          ..moveTo(at.dx, at.dy + s)
          ..cubicTo(at.dx, at.dy, at.dx, at.dy, at.dx + s, at.dy);
      case 1:
        path
          ..moveTo(at.dx, at.dy + s)
          ..cubicTo(at.dx, at.dy, at.dx, at.dy, at.dx - s, at.dy);
      case 2:
        path
          ..moveTo(at.dx, at.dy - s)
          ..cubicTo(at.dx, at.dy, at.dx, at.dy, at.dx + s, at.dy);
      default:
        path
          ..moveTo(at.dx, at.dy - s)
          ..cubicTo(at.dx, at.dy, at.dx, at.dy, at.dx - s, at.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _paintBase(Canvas canvas, Size size) {
    final baseTop = size.height * 0.88;
    final base = Path()
      ..moveTo(size.width * 0.08, baseTop)
      ..lineTo(size.width * 0.92, baseTop)
      ..lineTo(size.width * 0.96, size.height * 0.94)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.02,
        size.width * 0.04,
        size.height * 0.94,
      )
      ..close();
    canvas.drawPath(
      base,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFD4A574),
            Color(0xFF8B5A2B),
            Color(0xFF5C3A1A),
          ],
        ).createShader(
          Rect.fromLTWH(0, baseTop, size.width, size.height - baseTop),
        ),
    );

    final foot = Paint()..color = const Color(0xFF6B3F1A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.93,
          size.width * 0.12,
          size.height * 0.06,
        ),
        const Radius.circular(4),
      ),
      foot,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.76,
          size.height * 0.93,
          size.width * 0.12,
          size.height * 0.06,
        ),
        const Radius.circular(4),
      ),
      foot,
    );
  }

  @override
  bool shouldRepaint(covariant ModularCupboardPainter old) =>
      old.rows != rows || old.cols != cols;
}
