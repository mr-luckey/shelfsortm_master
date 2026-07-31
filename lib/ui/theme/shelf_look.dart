import 'package:flutter/material.dart';

import '../../models/theme_room.dart';

/// Per-theme shelf + room look (Sort Challenge variety).
class ShelfLook {
  final List<Color> plank;
  final List<Color> edge;
  final List<Color> roomBg;
  final Color bracket;
  final Color accent;
  final bool neon;
  final bool glitter;

  const ShelfLook({
    required this.plank,
    required this.edge,
    required this.roomBg,
    required this.bracket,
    required this.accent,
    this.neon = false,
    this.glitter = false,
  });

  static ShelfLook forStyle(String style) {
    switch (style) {
      case 'marble':
        return const ShelfLook(
          plank: [Color(0xFFF5F0EB), Color(0xFFE8DFD4), Color(0xFFD4C4B0)],
          edge: [Color(0xFFBCAAA4), Color(0xFF8D6E63)],
          roomBg: [Color(0xFFFFF0F5), Color(0xFFFFE4EC), Color(0xFFF8BBD0)],
          bracket: Color(0xFFEC407A),
          accent: Color(0xFFFF80AB),
        );
      case 'walnut':
        return const ShelfLook(
          plank: [Color(0xFF8D6E63), Color(0xFF6D4C41), Color(0xFF4E342E)],
          edge: [Color(0xFF3E2723), Color(0xFF1B0000)],
          roomBg: [Color(0xFF3E2723), Color(0xFF2C1810), Color(0xFF1A0F0A)],
          bracket: Color(0xFFFFD54F),
          accent: Color(0xFFFFB300),
        );
      case 'bamboo':
        return const ShelfLook(
          plank: [Color(0xFFDCEDC8), Color(0xFFC5E1A5), Color(0xFF9CCC65)],
          edge: [Color(0xFF689F38), Color(0xFF33691E)],
          roomBg: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
          bracket: Color(0xFF66BB6A),
          accent: Color(0xFF43A047),
        );
      case 'plastic':
        return const ShelfLook(
          plank: [Color(0xFF81D4FA), Color(0xFF4FC3F7), Color(0xFF29B6F6)],
          edge: [Color(0xFF0288D1), Color(0xFF01579B)],
          roomBg: [Color(0xFFE1F5FE), Color(0xFFB3E5FC), Color(0xFFFFF59D)],
          bracket: Color(0xFFFFCA28),
          accent: Color(0xFFFF7043),
        );
      case 'acrylic':
        return const ShelfLook(
          plank: [Color(0xFFF8BBD0), Color(0xFFF48FB1), Color(0xFFEC407A)],
          edge: [Color(0xFFAD1457), Color(0xFF880E4F)],
          roomBg: [Color(0xFFFCE4EC), Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
          bracket: Color(0xFFCE93D8),
          accent: Color(0xFFAB47BC),
        );
      case 'metal':
        return const ShelfLook(
          plank: [Color(0xFF90A4AE), Color(0xFF607D8B), Color(0xFF455A64)],
          edge: [Color(0xFF263238), Color(0xFF102027)],
          roomBg: [Color(0xFF1A237E), Color(0xFF0D1440), Color(0xFF000051)],
          bracket: Color(0xFF00E5FF),
          accent: Color(0xFF76FF03),
          neon: true,
        );
      case 'stall':
        return const ShelfLook(
          plank: [Color(0xFFFFE0B2), Color(0xFFFFCC80), Color(0xFFFFB74D)],
          edge: [Color(0xFFE65100), Color(0xFFBF360C)],
          roomBg: [Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFFFCCBC)],
          bracket: Color(0xFFFF5722),
          accent: Color(0xFFFFC107),
        );
      case 'minimal':
        return const ShelfLook(
          plank: [Color(0xFFFAFAFA), Color(0xFFEEEEEE), Color(0xFFBDBDBD)],
          edge: [Color(0xFF757575), Color(0xFF424242)],
          roomBg: [Color(0xFFECEFF1), Color(0xFFCFD8DC), Color(0xFFB0BEC5)],
          bracket: Color(0xFF78909C),
          accent: Color(0xFF546E7A),
        );
      case 'festive':
        return const ShelfLook(
          plank: [Color(0xFFFFCDD2), Color(0xFFEF9A9A), Color(0xFFE57373)],
          edge: [Color(0xFFC62828), Color(0xFF8E0000)],
          roomBg: [Color(0xFF1B5E20), Color(0xFF0D3B12), Color(0xFF1A237E)],
          bracket: Color(0xFFFFD700),
          accent: Color(0xFFFF5252),
          glitter: true,
        );
      case 'oak':
      default:
        return const ShelfLook(
          plank: [Color(0xFFE8C9A0), Color(0xFFD2A679), Color(0xFFB8956A)],
          edge: [Color(0xFF8B5A2B), Color(0xFF5D3A1A)],
          roomBg: [Color(0xFF2A3548), Color(0xFF1A2332), Color(0xFF121820)],
          bracket: Color(0xFFFFB74D),
          accent: Color(0xFFFF8A65),
        );
    }
  }
}

/// Exciting layout / motion twist per level.
enum LevelSpice {
  classic,
  floating, // shelves float with soft bob
  staggered, // alternate rows offset
  framed, // big wood cabinet frame around board
  spotlight, // vignette + glow on selected
  neonPulse, // metal/game den pulse
  bossArena, // thick gold frame + sparkles
}

LevelSpice spiceForLevel(int levelId, String shelfStyle) {
  if (levelId % ThemeRoom.levelsPerFlavor == 0) {
    return LevelSpice.bossArena;
  }
  if (shelfStyle == 'metal') return LevelSpice.neonPulse;
  if (levelId % 10 == 0) return LevelSpice.framed;
  if (levelId % 7 == 0) return LevelSpice.floating;
  if (levelId % 5 == 0) return LevelSpice.staggered;
  if (levelId % 3 == 0) return LevelSpice.spotlight;
  return LevelSpice.classic;
}
