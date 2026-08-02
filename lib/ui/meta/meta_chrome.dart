import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/audio_service.dart';
import '../premium/premium_tokens.dart';

void _uiTap(BuildContext context) {
  try {
    context.read<AudioService>().playButton();
  } catch (_) {
    HapticFeedback.selectionClick();
  }
}

/// Shared premium chrome for meta screens (not gameplay).
abstract final class MetaChrome {
  static const ui = PremiumTokens.uiRoot;
  static const bgAsset = '$ui/meta_room_bg.png';
  static const panelAsset = '$ui/meta_wood_panel.png';
  static const playBtnAsset = '$ui/meta_play_btn.png';
  static const starBadgeAsset = '$ui/meta_star_badge.png';

  static const cream = Color(0xFFF7E6C8);
  static const ink = Color(0xFF2A1608);
  static const inkSoft = Color(0xFF6B4A2E);
  static const gold = Color(0xFFE8C45A);
  static const brass = Color(0xFFB8860B);
  static const navWood = Color(0xFF3A2412);
}

/// Full-bleed room background used by meta screens.
class MetaBackdrop extends StatelessWidget {
  final Widget child;
  final bool dim;

  const MetaBackdrop({super.key, required this.child, this.dim = true});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          MetaChrome.bgAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) => const ColoredBox(
            color: Color(0xFF1A2F5A),
          ),
        ),
        if (dim)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66120A04),
                  Color(0x99120A04),
                ],
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class MetaTitle extends StatelessWidget {
  final String text;
  final double size;

  const MetaTitle(this.text, {super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: MetaChrome.cream,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class MetaSubtitle extends StatelessWidget {
  final String text;

  const MetaSubtitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: MetaChrome.cream.withValues(alpha: 0.85),
      ),
    );
  }
}

/// Wood plank card / panel.
class MetaWoodCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const MetaWoodCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                MetaChrome.panelAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const ColoredBox(
                  color: Color(0xFF5A3418),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC3A2410),
                  border: Border.all(color: MetaChrome.brass, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class MetaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const MetaPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed == null
            ? null
            : () {
                _uiTap(context);
                onPressed!();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: color.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: MetaChrome.gold, width: 1.5),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class MetaSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const MetaSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed == null
            ? null
            : () {
                _uiTap(context);
                onPressed!();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: MetaChrome.cream,
          side: const BorderSide(color: MetaChrome.gold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class MetaPlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const MetaPlayButton({
    super.key,
    required this.onPressed,
    this.label = 'PLAY',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _uiTap(context);
        onPressed();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            MetaChrome.playBtnAsset,
            width: 112,
            height: 112,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8C45A), Color(0xFF8A5A10)],
                ),
                border: Border.all(color: MetaChrome.cream, width: 3),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF2A1608),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: MetaChrome.cream,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1100.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Wood-style bottom navigation.
class MetaBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const MetaBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  static const _items = [
    (Icons.storefront_rounded, 'Home'),
    (Icons.map_rounded, 'Map'),
    (Icons.card_giftcard_rounded, 'Rewards'),
    (Icons.shopping_bag_rounded, 'Shop'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MetaChrome.navWood,
        border: const Border(
          top: BorderSide(color: MetaChrome.brass, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _uiTap(context);
                      onChanged(i);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[i].$1,
                          size: 24,
                          color: i == index
                              ? MetaChrome.gold
                              : MetaChrome.cream.withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _items[i].$2,
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: i == index
                                ? MetaChrome.gold
                                : MetaChrome.cream.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
