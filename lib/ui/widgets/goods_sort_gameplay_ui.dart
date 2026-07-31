import 'package:flutter/material.dart';

import '../../app/theme/goods_sort_theme.dart';

/// Pixel specs from Goods Sort™ gameplay screenshots (Play Store).
abstract final class GoodsSortLayout {
  static const bgTop = Color(0xFFF7EED8);
  static const bgBottom = Color(0xFFE8D5B5);
  static const cabinetFrame = Color(0xFF5D4037);
  static const boosterBar = Color(0xFF3E2723);

  static const headerHeight = 56.0;
  static const progressHeight = 8.0;
  static const boosterBarHeight = 76.0;
  static const shelfRowHeight = 100.0;
  static const plankHeight = 12.0;
  static const itemSizeOnShelf = 56.0;

  static BoxDecoration get screenBg => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
        image: DecorationImage(
          image: AssetImage('assets/images/rooms/gameplay_room_bg.png'),
          fit: BoxFit.cover,
        ),
      );
}

class GoodsSortTopBar extends StatelessWidget {
  final String levelText;
  final String timeText;
  final bool urgent;
  final bool frozen;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const GoodsSortTopBar({
    super.key,
    required this.levelText,
    required this.timeText,
    required this.onBack,
    required this.onSettings,
    this.urgent = false,
    this.frozen = false,
  });

  @override
  Widget build(BuildContext context) {
    final timerBg = urgent
        ? const Color(0xFFFFCDD2)
        : frozen
            ? const Color(0xFFB3E5FC)
            : const Color(0xFFC8E6C9);
    final timerBorder = urgent
        ? const Color(0xFFE53935)
        : frozen
            ? const Color(0xFF0288D1)
            : GoodsSortTheme.playGreen;

    return SizedBox(
      height: GoodsSortLayout.headerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _RoundIconButton(
              icon: Icons.settings_rounded,
              onTap: onSettings,
              bg: Colors.white.withValues(alpha: 0.95),
              iconColor: GoodsSortLayout.cabinetFrame,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: GoodsSortTheme.playGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: GoodsSortTheme.playGreen.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                levelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: timerBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: timerBorder, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    frozen ? Icons.ac_unit : Icons.timer_outlined,
                    size: 18,
                    color: GoodsSortLayout.cabinetFrame,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF3E2723),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _RoundIconButton(
              icon: Icons.home_rounded,
              onTap: onBack,
              bg: Colors.white.withValues(alpha: 0.95),
              iconColor: GoodsSortLayout.cabinetFrame,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color iconColor;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

class GoodsSortProgressBar extends StatelessWidget {
  final double ratio;

  const GoodsSortProgressBar({super.key, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: GoodsSortLayout.progressHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black.withValues(alpha: 0.12)),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.02, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        GoodsSortTheme.playGreenLight,
                        GoodsSortTheme.playGreen,
                      ],
                    ),
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

class GoodsSortBoosterBar extends StatelessWidget {
  final int freezes;
  final int shuffles;
  final int hammers;
  final int extras;
  final void Function(String id) onPressed;

  const GoodsSortBoosterBar({
    super.key,
    required this.freezes,
    required this.shuffles,
    required this.hammers,
    required this.extras,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GoodsSortLayout.boosterBarHeight,
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: GoodsSortLayout.boosterBar,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6D4C41), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BoosterBtn(
            icon: Icons.undo_rounded,
            count: null,
            color: const Color(0xFFFFCC80),
            onTap: () => onPressed('undo'),
          ),
          _BoosterBtn(
            icon: Icons.ac_unit_rounded,
            count: freezes,
            color: const Color(0xFF81D4FA),
            onTap: () => onPressed('freeze'),
          ),
          _BoosterBtn(
            icon: Icons.shuffle_rounded,
            count: shuffles,
            color: const Color(0xFFFFAB91),
            onTap: () => onPressed('shuffle'),
          ),
          _BoosterBtn(
            icon: Icons.hardware_rounded,
            count: hammers,
            color: const Color(0xFFCE93D8),
            onTap: () => onPressed('hammer'),
          ),
          _BoosterBtn(
            icon: Icons.add_box_rounded,
            count: extras,
            color: const Color(0xFFA5D6A7),
            onTap: () => onPressed('shelf'),
          ),
        ],
      ),
    );
  }
}

class _BoosterBtn extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color color;
  final VoidCallback onTap;

  const _BoosterBtn({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.22),
              border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (count != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: count! > 0 ? GoodsSortTheme.playGreen : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GoodsSortPauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const GoodsSortPauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paused',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoodsSortTheme.playGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onResume,
                child: const Text(
                  'Continue',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRestart, child: const Text('Restart')),
            TextButton(onPressed: onQuit, child: const Text('Quit')),
          ],
        ),
      ),
    );
  }
}

class GoodsSortLoseOverlay extends StatelessWidget {
  final bool isTime;
  final VoidCallback onWatchAd;
  final VoidCallback onQuit;

  const GoodsSortLoseOverlay({
    super.key,
    required this.isTime,
    required this.onWatchAd,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTime ? "Time's Up!" : 'No Space Left!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isTime ? '+60 seconds to keep sorting' : 'Add a shelf to continue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF757575)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onQuit,
                    child: const Text('Quit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GoodsSortTheme.playGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onWatchAd,
                    child: const Text('Watch Ad'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GoodsSortCupboard extends StatelessWidget {
  final Widget child;

  const GoodsSortCupboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7D5A48),
            Color(0xFF5D4037),
            Color(0xFF4E342E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        clipBehavior: Clip.none,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Crown molding
            Container(
              height: 16,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8D6E63),
                    Color(0xFF6D4C41),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8EDD8),
                      Color(0xFFEED9B8),
                      Color(0xFFE2C9A0),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  clipBehavior: Clip.none,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Use [GoodsSortCupboard]
class GoodsSortCabinetFrame extends StatelessWidget {
  final Widget child;

  const GoodsSortCabinetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GoodsSortCupboard(child: child);
}
