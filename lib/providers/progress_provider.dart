import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/level_repository.dart';
import '../models/player_progress.dart';
import '../services/ad_service.dart';
import '../services/iap_service.dart';
import '../services/save_service.dart';

class ProgressProvider extends ChangeNotifier {
  final SaveService saveService;
  final AdService adService;
  final IapService iapService;

  PlayerProgress progress = PlayerProgress.initial();
  bool ready = false;

  ProgressProvider({
    required this.saveService,
    required this.adService,
    required this.iapService,
  });

  Future<void> init() async {
    await saveService.init();
    progress = await saveService.loadProgress();
    // Testing: unlock entire campaign map.
    progress = progress.withAllLevelsUnlocked();
    _resetToolsIfNeeded();
    _syncDailyChallengeDate();
    ready = true;
    notifyListeners();
    await _persist();
  }

  /// Unlock every campaign level and persist (testing helper).
  Future<void> unlockAllLevelsForTesting() async {
    progress = progress.withAllLevelsUnlocked();
    notifyListeners();
    await _persist();
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _resetToolsIfNeeded() {
    if (progress.toolsResetDate == _today) return;
    progress = progress.copyWith(
      hintsRemaining: 3,
      shufflesRemaining: 2,
      autoSortRemaining: 1,
      extraShelfRemaining: 1,
      toolsResetDate: _today,
    );
  }

  void _syncDailyChallengeDate() {
    if (progress.lastDailyChallengeDate != _today) {
      progress = progress.copyWith(
        lastDailyChallengeDate: _today,
        dailyChallengeCompleted: false,
      );
    }
  }

  Future<void> _persist() => saveService.saveProgress(progress);

  Future<void> completeLevel({
    required int levelId,
    required int stars,
    required int moves,
    required int coinsEarned,
  }) async {
    final levels = Map<int, LevelProgress>.from(progress.levels);
    final existing = levels[levelId] ??
        LevelProgress(levelId: levelId, unlocked: levelId == 1);
    final bestStars =
        stars > existing.bestStars ? stars : existing.bestStars;
    final bestMoves =
        moves < existing.bestMoves ? moves : existing.bestMoves;
    levels[levelId] = existing.copyWith(
      bestStars: bestStars,
      bestMoves: bestMoves,
      playCount: existing.playCount + 1,
      unlocked: true,
    );

    final nextId = levelId + 1;
    if (nextId <= LevelRepository.instance.totalLevels) {
      final next = levels[nextId] ?? LevelProgress(levelId: nextId);
      levels[nextId] = next.copyWith(unlocked: true);
    }

    final gemBonus = stars >= 3 ? 3 : 0;
    final starDelta = bestStars > existing.bestStars
        ? bestStars - existing.bestStars
        : 0;

    progress = progress.copyWith(
      levels: levels,
      coins: progress.coins + coinsEarned,
      gems: progress.gems + gemBonus,
      currentLevel: nextId > progress.currentLevel &&
              nextId <= LevelRepository.instance.totalLevels
          ? nextId
          : progress.currentLevel,
      totalStars: progress.totalStars + starDelta,
    );

    if (levelId == 1) {
      _unlockAchievement('first_sort');
    }
    await _persist();
    notifyListeners();
  }

  void _unlockAchievement(String id) {
    if (progress.achievements.contains(id)) return;
    progress = progress.copyWith(
      achievements: {...progress.achievements, id},
    );
  }

  Future<void> spendHint() async {
    if (progress.hintsRemaining <= 0) return;
    progress =
        progress.copyWith(hintsRemaining: progress.hintsRemaining - 1);
    await _persist();
    notifyListeners();
  }

  Future<void> spendShuffle() async {
    if (progress.shufflesRemaining <= 0) return;
    progress = progress.copyWith(
      shufflesRemaining: progress.shufflesRemaining - 1,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> spendAutoSort() async {
    if (progress.autoSortRemaining <= 0) return;
    progress = progress.copyWith(
      autoSortRemaining: progress.autoSortRemaining - 1,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> spendExtraShelf() async {
    if (progress.extraShelfRemaining <= 0) return;
    progress = progress.copyWith(
      extraShelfRemaining: progress.extraShelfRemaining - 1,
    );
    await _persist();
    notifyListeners();
  }

  Future<bool> watchAdForTool(RewardType type) async {
    final ok = await adService.showRewarded(type);
    if (!ok) return false;
    switch (type) {
      case RewardType.hint:
        progress =
            progress.copyWith(hintsRemaining: progress.hintsRemaining + 1);
      case RewardType.shuffle:
        progress = progress.copyWith(
          shufflesRemaining: progress.shufflesRemaining + 1,
        );
      case RewardType.autoSort:
        progress = progress.copyWith(
          autoSortRemaining: progress.autoSortRemaining + 1,
        );
      case RewardType.extraShelf:
        progress = progress.copyWith(
          extraShelfRemaining: progress.extraShelfRemaining + 1,
        );
      case RewardType.doubleCoins:
        break;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  Future<int> claimDailyReward() async {
    _checkLoginStreak();
    final day = progress.loginStreak.clamp(1, 7);
    if (progress.claimedRewardDays.contains(day) &&
        progress.lastLoginDate == _today) {
      return -1; // already claimed
    }

    var coins = 0;
    var gems = 0;
    var hints = 0;
    var shuffles = 0;
    switch (day) {
      case 1:
        coins = 50;
      case 2:
        gems = 1;
        hints = 1;
      case 3:
        coins = 100;
      case 4:
        gems = 2;
      case 5:
        shuffles = 1;
        coins = 100;
      case 6:
        gems = 3;
      case 7:
        progress = progress.copyWith(
          ownedCosmetics: {...progress.ownedCosmetics, 'lucky_box_shelf'},
        );
    }

    progress = progress.copyWith(
      coins: progress.coins + coins,
      gems: progress.gems + gems,
      hintsRemaining: progress.hintsRemaining + hints,
      shufflesRemaining: progress.shufflesRemaining + shuffles,
      claimedRewardDays: {...progress.claimedRewardDays, day},
      lastLoginDate: _today,
    );
    await _persist();
    notifyListeners();
    return day;
  }

  void _checkLoginStreak() {
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
    if (progress.lastLoginDate == _today) return;
    if (progress.lastLoginDate == yesterday) {
      final next = progress.loginStreak >= 7 ? 1 : progress.loginStreak + 1;
      progress = progress.copyWith(
        loginStreak: next == 1 && progress.loginStreak == 7 ? 1 : next,
        claimedRewardDays: next == 1 ? {} : progress.claimedRewardDays,
      );
    } else {
      progress = progress.copyWith(loginStreak: 1, claimedRewardDays: {});
    }
  }

  Future<void> markTutorialDone() async {
    progress = progress.copyWith(tutorialDone: true);
    await _persist();
    notifyListeners();
  }

  Future<void> completeDailyChallenge({required int coins}) async {
    progress = progress.copyWith(
      dailyChallengeCompleted: true,
      lastDailyChallengeDate: _today,
      coins: progress.coins + coins,
        ownedCosmetics: {
        ...progress.ownedCosmetics,
        'daily_$_today',
      },
    );
    await _persist();
    notifyListeners();
  }

  Future<bool> restorePurchases() async {
    await iapService.restorePurchases();
    notifyListeners();
    return true;
  }

  Future<bool> purchase(IapProduct product) async {
    final ok = await iapService.purchase(product);
    if (!ok) return false;
    progress = progress.copyWith(
      coins: progress.coins + product.coins,
      gems: progress.gems + product.gems,
      hintsRemaining: progress.hintsRemaining + product.hints,
      removeAds: progress.removeAds || product.removeAds,
    );
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> buyCosmetic(
    String id, {
    int coinCost = 0,
    int gemCost = 0,
  }) async {
    if (progress.ownedCosmetics.contains(id)) return;
    if (progress.coins < coinCost || progress.gems < gemCost) return;
    progress = progress.copyWith(
      coins: progress.coins - coinCost,
      gems: progress.gems - gemCost,
      ownedCosmetics: {...progress.ownedCosmetics, id},
    );
    await _persist();
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    progress = progress.copyWith(coins: progress.coins + amount);
    await _persist();
    notifyListeners();
  }

  Future<void> setPlayerName(String name) async {
    progress = progress.copyWith(playerName: name);
    await _persist();
    notifyListeners();
  }
}
