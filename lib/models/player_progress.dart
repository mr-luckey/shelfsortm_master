class LevelProgress {
  final int levelId;
  final int bestStars;
  final int bestMoves;
  final int playCount;
  final bool unlocked;

  const LevelProgress({
    required this.levelId,
    this.bestStars = 0,
    this.bestMoves = 9999,
    this.playCount = 0,
    this.unlocked = false,
  });

  LevelProgress copyWith({
    int? bestStars,
    int? bestMoves,
    int? playCount,
    bool? unlocked,
  }) =>
      LevelProgress(
        levelId: levelId,
        bestStars: bestStars ?? this.bestStars,
        bestMoves: bestMoves ?? this.bestMoves,
        playCount: playCount ?? this.playCount,
        unlocked: unlocked ?? this.unlocked,
      );

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'bestStars': bestStars,
        'bestMoves': bestMoves,
        'playCount': playCount,
        'unlocked': unlocked,
      };

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
        levelId: json['levelId'] as int,
        bestStars: json['bestStars'] as int? ?? 0,
        bestMoves: json['bestMoves'] as int? ?? 9999,
        playCount: json['playCount'] as int? ?? 0,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class PlayerProgress {
  final String playerName;
  final int coins;
  final int gems;
  final int currentLevel;
  final Map<int, LevelProgress> levels;
  final int loginStreak;
  final String? lastLoginDate;
  final Set<int> claimedRewardDays;
  final bool tutorialDone;
  final bool removeAds;
  final Set<String> ownedCosmetics;
  final String? lastDailyChallengeDate;
  final bool dailyChallengeCompleted;
  final int hintsRemaining;
  final int shufflesRemaining;
  final int autoSortRemaining;
  final int extraShelfRemaining;
  final String? toolsResetDate;
  final int totalStars;
  final Set<String> achievements;

  const PlayerProgress({
    this.playerName = 'Sorter',
    this.coins = 0,
    this.gems = 0,
    this.currentLevel = 1,
    this.levels = const {},
    this.loginStreak = 0,
    this.lastLoginDate,
    this.claimedRewardDays = const {},
    this.tutorialDone = false,
    this.removeAds = false,
    this.ownedCosmetics = const {},
    this.lastDailyChallengeDate,
    this.dailyChallengeCompleted = false,
    this.hintsRemaining = 3,
    this.shufflesRemaining = 2,
    this.autoSortRemaining = 1,
    this.extraShelfRemaining = 1,
    this.toolsResetDate,
    this.totalStars = 0,
    this.achievements = const {},
  });

  static PlayerProgress initial() {
    return PlayerProgress(
      levels: {
        1: const LevelProgress(levelId: 1, unlocked: true),
      },
    );
  }

  LevelProgress levelOf(int id) =>
      levels[id] ?? LevelProgress(levelId: id, unlocked: id == 1);

  PlayerProgress copyWith({
    String? playerName,
    int? coins,
    int? gems,
    int? currentLevel,
    Map<int, LevelProgress>? levels,
    int? loginStreak,
    String? lastLoginDate,
    Set<int>? claimedRewardDays,
    bool? tutorialDone,
    bool? removeAds,
    Set<String>? ownedCosmetics,
    String? lastDailyChallengeDate,
    bool? dailyChallengeCompleted,
    int? hintsRemaining,
    int? shufflesRemaining,
    int? autoSortRemaining,
    int? extraShelfRemaining,
    String? toolsResetDate,
    int? totalStars,
    Set<String>? achievements,
  }) =>
      PlayerProgress(
        playerName: playerName ?? this.playerName,
        coins: coins ?? this.coins,
        gems: gems ?? this.gems,
        currentLevel: currentLevel ?? this.currentLevel,
        levels: levels ?? this.levels,
        loginStreak: loginStreak ?? this.loginStreak,
        lastLoginDate: lastLoginDate ?? this.lastLoginDate,
        claimedRewardDays: claimedRewardDays ?? this.claimedRewardDays,
        tutorialDone: tutorialDone ?? this.tutorialDone,
        removeAds: removeAds ?? this.removeAds,
        ownedCosmetics: ownedCosmetics ?? this.ownedCosmetics,
        lastDailyChallengeDate:
            lastDailyChallengeDate ?? this.lastDailyChallengeDate,
        dailyChallengeCompleted:
            dailyChallengeCompleted ?? this.dailyChallengeCompleted,
        hintsRemaining: hintsRemaining ?? this.hintsRemaining,
        shufflesRemaining: shufflesRemaining ?? this.shufflesRemaining,
        autoSortRemaining: autoSortRemaining ?? this.autoSortRemaining,
        extraShelfRemaining: extraShelfRemaining ?? this.extraShelfRemaining,
        toolsResetDate: toolsResetDate ?? this.toolsResetDate,
        totalStars: totalStars ?? this.totalStars,
        achievements: achievements ?? this.achievements,
      );

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'coins': coins,
        'gems': gems,
        'currentLevel': currentLevel,
        'levels': levels.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'loginStreak': loginStreak,
        'lastLoginDate': lastLoginDate,
        'claimedRewardDays': claimedRewardDays.toList(),
        'tutorialDone': tutorialDone,
        'removeAds': removeAds,
        'ownedCosmetics': ownedCosmetics.toList(),
        'lastDailyChallengeDate': lastDailyChallengeDate,
        'dailyChallengeCompleted': dailyChallengeCompleted,
        'hintsRemaining': hintsRemaining,
        'shufflesRemaining': shufflesRemaining,
        'autoSortRemaining': autoSortRemaining,
        'extraShelfRemaining': extraShelfRemaining,
        'toolsResetDate': toolsResetDate,
        'totalStars': totalStars,
        'achievements': achievements.toList(),
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final levelsRaw = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <int, LevelProgress>{};
    for (final e in levelsRaw.entries) {
      levels[int.parse(e.key)] =
          LevelProgress.fromJson(e.value as Map<String, dynamic>);
    }
    return PlayerProgress(
      playerName: json['playerName'] as String? ?? 'Sorter',
      coins: json['coins'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      levels: levels,
      loginStreak: json['loginStreak'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] as String?,
      claimedRewardDays:
          (json['claimedRewardDays'] as List?)?.map((e) => e as int).toSet() ??
              {},
      tutorialDone: json['tutorialDone'] as bool? ?? false,
      removeAds: json['removeAds'] as bool? ?? false,
      ownedCosmetics:
          (json['ownedCosmetics'] as List?)?.map((e) => e as String).toSet() ??
              {},
      lastDailyChallengeDate: json['lastDailyChallengeDate'] as String?,
      dailyChallengeCompleted:
          json['dailyChallengeCompleted'] as bool? ?? false,
      hintsRemaining: json['hintsRemaining'] as int? ?? 3,
      shufflesRemaining: json['shufflesRemaining'] as int? ?? 2,
      autoSortRemaining: json['autoSortRemaining'] as int? ?? 1,
      extraShelfRemaining: json['extraShelfRemaining'] as int? ?? 1,
      toolsResetDate: json['toolsResetDate'] as String?,
      totalStars: json['totalStars'] as int? ?? 0,
      achievements:
          (json['achievements'] as List?)?.map((e) => e as String).toSet() ??
              {},
    );
  }
}
