import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFF6B35);
  static const secondary = Color(0xFFFFD700);
  static const background = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF2D2D2D);
  static const textLight = Color(0xFF7A7A7A);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFF44336);
  static const accent = Color(0xFF9C27B0);
  static const wood = Color(0xFF8B5A2B);
  static const woodLight = Color(0xFFC4A484);
  static const woodDark = Color(0xFF5D3A1A);

  static const itemRed = Color(0xFFE53935);
  static const itemBlue = Color(0xFF1E88E5);
  static const itemGreen = Color(0xFF43A047);
  static const itemYellow = Color(0xFFFDD835);
  static const itemPurple = Color(0xFF8E24AA);
  static const itemOrange = Color(0xFFFB8C00);
  static const itemPink = Color(0xFFEC407A);
  static const itemTeal = Color(0xFF00897B);

  static Color forItemColor(String color) {
    switch (color) {
      case 'red':
        return itemRed;
      case 'blue':
        return itemBlue;
      case 'green':
        return itemGreen;
      case 'yellow':
        return itemYellow;
      case 'purple':
        return itemPurple;
      case 'orange':
        return itemOrange;
      case 'pink':
        return itemPink;
      case 'teal':
        return itemTeal;
      default:
        return itemOrange;
    }
  }

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFFB347)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient themeGradient(String themeId) {
    switch (themeId) {
      case 'activities':
        return const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'animals':
        return const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'food':
        return const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFE4EC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'hands':
        return const LinearGradient(
          colors: [Color(0xFFF3E5F5), Color(0xFFFCE4EC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'objects':
        return const LinearGradient(
          colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'people':
        return const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFFFF9C4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'people_activities':
        return const LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'people_professions':
        return const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'smilies':
        return const LinearGradient(
          colors: [Color(0xFFFAFAFA), Color(0xFFECEFF1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'symbols':
        return const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFF8E1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'travel':
        return const LinearGradient(
          colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      default:
        return const LinearGradient(
          colors: [background, Color(0xFFFFE8D6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}
