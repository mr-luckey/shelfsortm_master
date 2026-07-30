import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../models/item.dart';

/// Procedural isometric 3D product — no external model files required.
class Product3DView extends StatelessWidget {
  final GameItem item;
  final double size;
  final bool lifting;
  final bool dimmed;

  const Product3DView({
    super.key,
    required this.item,
    this.size = 48,
    this.lifting = false,
    this.dimmed = false,
  });

  static ProductShape shapeFor(String type) {
    switch (type) {
      case 'mug':
      case 'cup':
      case 'jar':
      case 'sauce':
      case 'perfume':
      case 'cream':
      case 'can':
      case 'pot':
        return ProductShape.bottle;
      case 'box':
      case 'snack':
      case 'bag':
      case 'book':
      case 'frame':
        return ProductShape.box;
      case 'ball':
      case 'globe':
      case 'teddy':
      case 'ornament':
        return ProductShape.sphere;
      case 'cupcake':
      case 'macaron':
      case 'block':
        return ProductShape.cylinder;
      default:
        return ProductShape.bottle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forItemColor(item.color);
    final shape = shapeFor(item.type);
    final w = size * 0.78;
    final h = size * (shape == ProductShape.bottle ? 1.15 : 0.95);

    Widget child = SizedBox(
      width: w,
      height: h + 8,
      child: CustomPaint(
        painter: _Product3DPainter(
          color: color,
          shape: shape,
          emoji: GoodsEmojiGlyph.forType(item.type),
        ),
        size: Size(w, h),
      ),
    );

    if (lifting) {
      child = Transform.translate(
        offset: const Offset(0, -4),
        child: child,
      );
    }
    if (dimmed) {
      child = Opacity(opacity: 0.22, child: child);
    }
    return child;
  }
}

/// Emoji lookup kept here so painter can draw label on product face.
abstract final class GoodsEmojiGlyph {
  static String forType(String type) {
    const map = {
      'mug': '☕', 'cup': '🥤', 'jar': '🍯', 'cupcake': '🧁', 'box': '📦',
      'macaron': '🍪', 'book': '📚', 'candle': '🕯️', 'globe': '🌍',
      'pot': '🪴', 'can': '🥫', 'seed': '🌱', 'teddy': '🧸', 'block': '🧱',
      'ball': '⚽', 'perfume': '🧴', 'lipstick': '💄', 'cream': '🫧',
      'controller': '🎮', 'cartridge': '💾', 'headset': '🎧', 'sauce': '🍾',
      'snack': '🍿', 'vase': '🏺', 'frame': '🖼️', 'ribbon': '🎀',
      'bag': '🛍️', 'ornament': '🎁',
    };
    return map[type] ?? '✨';
  }
}

enum ProductShape { bottle, box, sphere, cylinder }

class _Product3DPainter extends CustomPainter {
  final Color color;
  final ProductShape shape;
  final String emoji;

  _Product3DPainter({
    required this.color,
    required this.shape,
    required this.emoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height - 2;

    // Ground shadow (Goods Puzzle contact shadow)
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY),
        width: size.width * 0.72,
        height: 8,
      ),
      shadow,
    );

    switch (shape) {
      case ProductShape.bottle:
        _drawBottle(canvas, size, cx, groundY);
      case ProductShape.box:
        _drawBox(canvas, size, cx, groundY);
      case ProductShape.sphere:
        _drawSphere(canvas, size, cx, groundY);
      case ProductShape.cylinder:
        _drawCylinder(canvas, size, cx, groundY);
    }

    // Product emoji label on front face
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size.width * 0.38)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, size.height * 0.38 - tp.height / 2),
    );
  }

  void _drawBottle(Canvas canvas, Size size, double cx, double groundY) {
    final bodyH = size.height * 0.72;
    final bodyW = size.width * 0.52;
    final top = groundY - bodyH;

    // Back face (darker)
    final back = Path()
      ..moveTo(cx - bodyW * 0.35, top + bodyH * 0.15)
      ..lineTo(cx - bodyW * 0.5, groundY - 4)
      ..lineTo(cx, groundY)
      ..lineTo(cx, top + bodyH * 0.12)
      ..close();
    canvas.drawPath(
      back,
      Paint()..color = Color.lerp(color, Colors.black, 0.35)!,
    );

    // Front face
    final front = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - bodyW * 0.42, top, bodyW * 0.84, bodyH),
      Radius.circular(bodyW * 0.22),
    );
    canvas.drawRRect(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.5)!,
            color,
            Color.lerp(color, Colors.black, 0.15)!,
          ],
        ).createShader(front.outerRect),
    );

    // Right side face
    final side = Path()
      ..moveTo(cx + bodyW * 0.42, top + 2)
      ..lineTo(cx + bodyW * 0.55, top + bodyH * 0.18)
      ..lineTo(cx + bodyW * 0.55, groundY - 2)
      ..lineTo(cx + bodyW * 0.42, groundY - 4)
      ..close();
    canvas.drawPath(
      side,
      Paint()..color = Color.lerp(color, Colors.black, 0.22)!,
    );

    // Cap
    final cap = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, top - 2),
        width: bodyW * 0.38,
        height: 8,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(cap, Paint()..color = Color.lerp(color, Colors.black, 0.4)!);

    // Specular
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW * 0.28, top + 6, bodyW * 0.14, bodyH * 0.45),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _drawBox(Canvas canvas, Size size, double cx, double groundY) {
    final w = size.width * 0.62;
    final h = size.height * 0.58;
    final top = groundY - h;
    final depth = w * 0.22;

    // Top face
    final topFace = Path()
      ..moveTo(cx - w / 2, top + depth * 0.5)
      ..lineTo(cx, top)
      ..lineTo(cx + w / 2, top + depth * 0.5)
      ..lineTo(cx, top + depth)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = Color.lerp(color, Colors.white, 0.35)!,
    );

    // Left face
    final left = Path()
      ..moveTo(cx - w / 2, top + depth * 0.5)
      ..lineTo(cx - w / 2, groundY)
      ..lineTo(cx, groundY - depth * 0.3)
      ..lineTo(cx, top + depth)
      ..close();
    canvas.drawPath(left, Paint()..color = color);

    // Right face
    final right = Path()
      ..moveTo(cx + w / 2, top + depth * 0.5)
      ..lineTo(cx + w / 2, groundY)
      ..lineTo(cx, groundY - depth * 0.3)
      ..lineTo(cx, top + depth)
      ..close();
    canvas.drawPath(
      right,
      Paint()..color = Color.lerp(color, Colors.black, 0.2)!,
    );

    canvas.drawLine(
      Offset(cx - w / 2, top + depth * 0.5),
      Offset(cx + w / 2, top + depth * 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.2,
    );
  }

  void _drawSphere(Canvas canvas, Size size, double cx, double groundY) {
    final r = size.width * 0.34;
    final cy = groundY - r - 2;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Color.lerp(color, Colors.white, 0.55)!,
            color,
            Color.lerp(color, Colors.black, 0.25)!,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    canvas.drawCircle(
      Offset(cx - r * 0.28, cy - r * 0.32),
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _drawCylinder(Canvas canvas, Size size, double cx, double groundY) {
    final w = size.width * 0.55;
    final h = size.height * 0.5;
    final top = groundY - h;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, top),
          width: w,
          height: h * 0.22,
        ),
        Radius.circular(w / 2),
      ),
      Paint()..color = Color.lerp(color, Colors.white, 0.3)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w / 2, top, w, h),
        Radius.circular(w * 0.35),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(color, Colors.black, 0.15)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
        ).createShader(Rect.fromLTWH(cx - w / 2, top, w, h)),
    );
  }

  @override
  bool shouldRepaint(covariant _Product3DPainter old) =>
      old.color != color || old.shape != shape || old.emoji != emoji;
}

/// Supermarket cabinet back panel + side walls.
class CabinetBackdrop extends StatelessWidget {
  final Widget child;
  final Color plankColor;
  final double scale;

  const CabinetBackdrop({
    super.key,
    required this.child,
    required this.plankColor,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Recessed back panel
        Positioned.fill(
          child: Container(
            margin: EdgeInsets.fromLTRB(4 * scale, 2 * scale, 4 * scale, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * scale),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(plankColor, Colors.black, 0.45)!,
                  Color.lerp(plankColor, Colors.black, 0.65)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
          ),
        ),
        // Metal side rails
        Positioned(
          left: 0,
          top: 8 * scale,
          bottom: 12 * scale,
          child: Container(
            width: 3 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade600,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 8 * scale,
          bottom: 12 * scale,
          child: Container(
            width: 3 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade600,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
