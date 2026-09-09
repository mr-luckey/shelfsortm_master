import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../bloc/audio_cubit.dart';
import '../../models/player_progress.dart';
import '../../providers/progress_provider.dart';
import '../meta/meta_chrome.dart';
import '../premium/premium_tokens.dart';
import '../widgets/ad_banner_widget.dart';
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
}

sealed class _ListEntry {
  const _ListEntry();
}

class _TitleEntry extends _ListEntry {
  final String title;
  const _TitleEntry(this.title);
}

class _LevelsRowEntry extends _ListEntry {
  final List<int> levelIds;
  const _LevelsRowEntry(this.levelIds);
}

/// Level select: named sections of 50 levels each, 5 shields per row.
class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  static const _perSection = 50;
  static const _cols = 5;

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

  static final List<_ListEntry> _entries = _buildEntries();

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

  static List<_ListEntry> _buildEntries() {
    final out = <_ListEntry>[];
    for (final section in _buildSections()) {
      out.add(_TitleEntry(section.title));
      for (var id = section.startLevel; id <= section.endLevel; id += _cols) {
        final end = (id + _cols - 1).clamp(id, section.endLevel);
        out.add(_LevelsRowEntry([
          for (var n = id; n <= end; n++) n,
        ]));
      }
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
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
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
                        Expanded(
                          child: Text(
                            'Levels',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: MetaChrome.cream,
                              fontWeight: FontWeight.w800,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 48.w),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _entries.length + 1,
                      cacheExtent: 400,
                      itemBuilder: (context, index) {
                        if (index == _entries.length) {
                          return SizedBox(height: 24.h);
                        }
                        final entry = _entries[index];
                        return switch (entry) {
                          _TitleEntry(:final title) => _sectionTitle(title),
                          _LevelsRowEntry(:final levelIds) =>
                            _levelsRow(context, levelIds, p),
                        };
                      },
                    ),
                  ),
                  const AdBannerWidget(placement: 'levels'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
      child: Text(
        title,
        style: TextStyle(
          color: MetaChrome.gold,
          fontWeight: FontWeight.w900,
          fontSize: 18.sp,
        ),
      ),
    );
  }

  static Widget _levelsRow(
    BuildContext context,
    List<int> levelIds,
    PlayerProgress p,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
      child: Row(
        children: [
          for (var i = 0; i < _cols; i++) ...[
            if (i > 0) SizedBox(width: 10.w),
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.88,
                child: i < levelIds.length
                    ? _LevelShieldTile(
                        levelId: levelIds[i],
                        unlocked: p.levelOf(levelIds[i]).unlocked,
                        onTap: () => _openLevel(context, p, levelIds[i]),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
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

class _LevelShieldTile extends StatelessWidget {
  final int levelId;
  final bool unlocked;
  final VoidCallback onTap;

  const _LevelShieldTile({
    required this.levelId,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              '${PremiumTokens.uiRoot}/level_shield.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.h, bottom: 10.h),
              child: unlocked
                  ? Text(
                      '$levelId',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: (levelId >= 1000 ? 11 : 15).sp,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 2),
                        ],
                      ),
                    )
                  : Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
