import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'premium_tokens.dart';

/// Cozy dark-blue room matching the reference screenshot.
class PremiumRoomBackground extends StatelessWidget {
  final Widget child;

  const PremiumRoomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft photo backdrop when available
        Positioned.fill(
          child: Image.asset(
            '${PremiumTokens.uiRoot}/room_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, error, stack) => const SizedBox.shrink(),
          ),
        ),
        // Painted room (ensures brand look even if asset missing)
        const Positioned.fill(child: CustomPaint(painter: _RoomPainter())),
        // Soft veil so board stays readable (no BackdropFilter — keep 60 FPS)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PremiumTokens.roomWallDeep.withValues(alpha: 0.28),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF243B6B),
          PremiumTokens.roomWall,
          PremiumTokens.roomWallDeep,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wall);

    // Window glow (right)
    final win = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.08, size.width * 0.22, size.height * 0.18),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      win,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PremiumTokens.windowGlow.withValues(alpha: 0.55),
            const Color(0xFF4A6FA5).withValues(alpha: 0.25),
          ],
        ).createShader(win.outerRect),
    );
    canvas.drawRRect(
      win,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Left plant shelf silhouette
    final plantX = size.width * 0.02;
    final plantY = size.height * 0.12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(plantX, plantY + 40, 42, 10),
        const Radius.circular(3),
      ),
      Paint()..color = PremiumTokens.woodMid.withValues(alpha: 0.7),
    );
    final leaf = Paint()..color = const Color(0xFF3D8B4F).withValues(alpha: 0.75);
    for (var i = 0; i < 5; i++) {
      final a = -0.6 + i * 0.3;
      final path = Path()
        ..moveTo(plantX + 22, plantY + 40)
        ..quadraticBezierTo(
          plantX + 22 + math.cos(a) * 28,
          plantY + 10,
          plantX + 22 + math.cos(a) * 18,
          plantY - 4,
        )
        ..quadraticBezierTo(
          plantX + 22 + math.cos(a) * 8,
          plantY + 16,
          plantX + 22,
          plantY + 40,
        );
      canvas.drawPath(path, leaf);
    }

    // Wooden floor
    final floorTop = size.height * 0.78;
    final floor = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          PremiumTokens.roomFloorLight.withValues(alpha: 0.85),
          PremiumTokens.roomFloor,
          const Color(0xFF4A2E18),
        ],
      ).createShader(Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop));
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop),
      floor,
    );

    // Floor planks
    final plank = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 8; i++) {
      final y = floorTop + (size.height - floorTop) * (i / 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), plank);
    }

    // Blue carpet
    final carpet = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.90,
        size.width * 0.84,
        size.height * 0.08,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      carpet,
      Paint()
        ..shader = LinearGradient(
          colors: [
            PremiumTokens.carpetBlue.withValues(alpha: 0.85),
            const Color(0xFF2A4578).withValues(alpha: 0.9),
          ],
        ).createShader(carpet.outerRect),
    );

    // Foreground leaves
    final fg = Paint()..color = const Color(0xFF2E7D32).withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromLTWH(-10, size.height * 0.92, 70, 50),
      fg,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width - 55, size.height * 0.93, 70, 45),
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
