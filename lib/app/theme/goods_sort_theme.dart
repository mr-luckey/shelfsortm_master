import 'package:flutter/material.dart';

/// Visual tokens aligned with Goods Sort™ (Shinrays) — green play, sky map, crisp items.
abstract final class GoodsSortTheme {
  static const playGreen = Color(0xFF43A047);
  static const playGreenDark = Color(0xFF2E7D32);
  static const playGreenLight = Color(0xFF66BB6A);

  static const mapSkyTop = Color(0xFF87CEEB);
  static const mapSkyMid = Color(0xFFB3E5FC);
  static const mapGrass = Color(0xFFA5D6A7);
  static const mapGrassDark = Color(0xFF81C784);
  static const pathTan = Color(0xFFD7CCC8);
  static const pathBrown = Color(0xFF8D6E63);

  static const homeSky = Color(0xFFE3F2FD);
  static const homeWarm = Color(0xFFFFF8E1);

  static LinearGradient get playGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [playGreenLight, playGreen, playGreenDark],
      );

  static LinearGradient get mapGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [mapSkyTop, mapSkyMid, mapGrass],
      );

  static LinearGradient get homeGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [homeSky, homeWarm, Color(0xFFFFF3E0)],
      );

  /// Strong ring colors — items must not blend (user review fix).
  static Color itemRing(String colorName) {
    switch (colorName) {
      case 'red':
        return const Color(0xFFD32F2F);
      case 'blue':
        return const Color(0xFF1565C0);
      case 'green':
        return const Color(0xFF2E7D32);
      case 'yellow':
        return const Color(0xFFF9A825);
      case 'purple':
        return const Color(0xFF6A1B9A);
      case 'orange':
        return const Color(0xFFEF6C00);
      case 'pink':
        return const Color(0xFFC2185B);
      case 'teal':
        return const Color(0xFF00695C);
      default:
        return const Color(0xFF546E7A);
    }
  }

  static Color itemPlateFill(String colorName) {
    return itemRing(colorName).withValues(alpha: 0.08);
  }
}
