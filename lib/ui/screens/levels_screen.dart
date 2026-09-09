import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bloc/audio_cubit.dart';
import '../../models/player_progress.dart';
import '../../providers/progress_provider.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_tokens.dart';
import 'level_intro_sheet.dart';

class _LevelSection {
  final String title;
  final int startLevel;
  final int endLevel;

  const _LevelSection({
    required this.title,
    required this.startLevel,
    required this.endLevel,
  });

  int get count => endLevel - startLevel + 1;

  List<int> get levelIds => [
        for (var id = startLevel; id <= endLevel; id++) id,
      ];
}

/// Level select: named sections of 50 levels each, 5 containers per row.
class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  static const _perSection = 50;

  static const _titles = [
    'Easy',
    'Normal',
    'Hard',
    'Tricky',
    'Expert',
    'Master',
    'Elite',
    'Champion',
    'Legend',
    'Epic',
    'Mythic',
    'Divine',
    'Supreme',
    'Ultimate',
    'Prestige',
    'Grandmaster',
    'Titan',
    'Infinity',
    'Cosmos',
    'Galaxy',
    'Universe',
    'Omega',
  ];

  static final List<_LevelSection> sections = _buildSections();

  static List<_LevelSection> _buildSections() {
    final total = PlayerProgress.totalLevels;
    final out = <_LevelSection>[];
    var start = 1;
    var i = 0;
    while (start <= total) {
      final end = (start + _perSection - 1).clamp(start, total);
      final title = i < _titles.length ? _titles[i] : 'Pack ${i + 1}';
      out.add(_LevelSection(title: title, startLevel: start, endLevel: end));
      start = end + 1;
      i++;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progress, _) {
        final p = progress.progress;

        return Scaffold(
          body: MetaBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            context.read<AudioCubit>().playButton();
                            Navigator.of(context).maybePop();
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: MetaChrome.cream,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Levels',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: MetaChrome.cream,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        for (final section in sections) ...[
                          _sectionTitle(section.title),
                          _levelGrid(section.levelIds, p),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: MetaChrome.gold,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  static Widget _levelGrid(List<int> ids, PlayerProgress p) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final id = ids[index];
            final lp = p.levelOf(id);
            return _LevelContainer(
              levelId: id,
              progress: lp,
              isCurrent: id == p.currentLevel,
              onTap: () => _openLevel(context, p, id),
            );
          },
          childCount: ids.length,
        ),
      ),
    );
  }

  static void _openLevel(BuildContext context, PlayerProgress p, int id) {
    final lp = p.levelOf(id);
    if (!lp.unlocked) {
      context.read<AudioCubit>().playInvalid();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete previous levels to unlock!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.read<AudioCubit>().playButton();
    launchLevel(context, levelId: id);
  }
}

class _LevelContainer extends StatelessWidget {
  final int levelId;
  final LevelProgress progress;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LevelContainer({
    required this.levelId,
    required this.progress,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.unlocked;

    final Color face;
    final Color ring;
    final Color textColor;
    if (!unlocked) {
      face = const Color(0xFF5C4030);
      ring = const Color(0xFF3E2723);
      textColor = Colors.white54;
    } else if (isCurrent) {
      face = PremiumTokens.hudBlue;
      ring = MetaChrome.cream;
      textColor = Colors.white;
    } else if (progress.bestStars >= 3) {
      face = PremiumTokens.coinGold;
      ring = MetaChrome.brass;
      textColor = PremiumTokens.woodDark;
    } else {
      face = const Color(0xEE2A1608);
      ring = MetaChrome.brass;
      textColor = MetaChrome.cream;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ring, width: isCurrent ? 2 : 1.5),
        ),
        alignment: Alignment.center,
        child: unlocked
            ? Text(
                '$levelId',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: levelId >= 1000 ? 12 : 15,
                ),
              )
            : Icon(
                Icons.lock_rounded,
                color: textColor,
                size: 20,
              ),
      ),
    );
  }
}
