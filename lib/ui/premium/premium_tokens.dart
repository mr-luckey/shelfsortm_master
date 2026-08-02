import 'package:flutter/material.dart';

/// Design tokens from reference screenshot (Level 36) — sole UI source of truth.
abstract final class PremiumTokens {
  // HUD
  static const hudNavy = Color(0xFF163A6B);
  static const hudNavyDark = Color(0xFF0E2A52);
  static const hudBlue = Color(0xFF1E5BB8);
  static const hudBlueLight = Color(0xFF4A90E2);
  static const coinGold = Color(0xFFFFC107);
  static const gemMagenta = Color(0xFFC2185B);
  static const gemPurple = Color(0xFFAB47BC);
  static const plusGreen = Color(0xFF43A047);
  static const starGold = Color(0xFFFFD54F);

  // Goal panel
  static const goalCream = Color(0xFFF7F0E6);
  static const goalBorder = Color(0xFFD9C4A8);
  static const goalBlue = Color(0xFF1E63C8);
  static const goalText = Color(0xFF1A3A6B);
  static const rewardInset = Color(0xFFE8EEF5);

  // Cupboard wood
  static const woodLight = Color(0xFFE8C9A0);
  static const woodMid = Color(0xFFD4A574);
  static const woodDark = Color(0xFF8B5A2B);
  static const woodFrame = Color(0xFFC4956A);
  static const cubbyBack = Color(0xFF5C3010);
  static const cubbyFloor = Color(0xFFB88955);

  // Toolbar
  static const undoBlue = Color(0xFF2196F3);
  static const shufflePurple = Color(0xFF8E24AA);
  static const freezeGreen = Color(0xFF43A047);
  static const slotPink = Color(0xFFE91E63);
  static const hintOrange = Color(0xFFFF9800);
  static const badgeRed = Color(0xFFE53935);

  // Room (screenshot)
  static const roomWall = Color(0xFF1A2F5A);
  static const roomWallDeep = Color(0xFF0F1F3D);
  static const roomFloor = Color(0xFF6B4226);
  static const roomFloorLight = Color(0xFF8B5A2B);
  static const carpetBlue = Color(0xFF3A5F9E);
  static const windowGlow = Color(0xFF7BA3D4);

  static const hudHeight = 88.0;
  static const goalHeight = 70.0;
  /// Reserved strip under the board for a banner ad.
  static const bannerAdHeight = 54.0;
  static const cupboardRadius = 16.0;
  static const frameWidth = 12.0;
  static const dividerWidth = 5.0;

  static const assetRoot = 'assets/images/premium';
  static const toyRoot = '$assetRoot/toys';
  static const uiRoot = '$assetRoot/ui';

  static List<BoxShadow> glossyShadow({double y = 4, double blur = 8}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
      ];

  static LinearGradient get glossyBlue => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5BA3F0), Color(0xFF1E5BB8), Color(0xFF154A96)],
      );

  static LinearGradient get woodGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [woodLight, woodMid, Color(0xFFB8956A)],
      );
}
