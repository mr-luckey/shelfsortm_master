import 'dart:math';

/// Context for gift-box rewarded loot.
enum GiftLootPool { gameplay, meta, doubleCoins }

/// One rolled reward after a successful rewarded ad.
sealed class GiftLoot {
  const GiftLoot();
  String get label;
}

class CoinsLoot extends GiftLoot {
  final int amount;
  const CoinsLoot(this.amount);
  @override
  String get label => '+$amount coins';
}

class GemsLoot extends GiftLoot {
  final int amount;
  const GemsLoot(this.amount);
  @override
  String get label => amount == 1 ? '+1 diamond' : '+$amount diamonds';
}

class GameplayHintLoot extends GiftLoot {
  const GameplayHintLoot();
  @override
  String get label => '+1 free hint';
}

class GameplayFreezeLoot extends GiftLoot {
  const GameplayFreezeLoot();
  @override
  String get label => '+1 free freeze';
}

class GameplayTimeLoot extends GiftLoot {
  final int seconds;
  const GameplayTimeLoot(this.seconds);
  @override
  String get label => '+$seconds sec';
}

class DoubleCoinsLoot extends GiftLoot {
  const DoubleCoinsLoot();
  @override
  String get label => '2x coins';
}

/// Weighted random tables for gift boxes.
abstract final class GiftLootTables {
  static final _rng = Random();

  /// In-level: hint / freeze / +30s (roughly even).
  static GiftLoot rollGameplay([Random? rng]) {
    final r = (rng ?? _rng).nextInt(100);
    if (r < 34) return const GameplayHintLoot();
    if (r < 67) return const GameplayFreezeLoot();
    return const GameplayTimeLoot(30);
  }

  /// Home / ASMR: coins & diamonds. 30 coins and 10 diamonds are rare.
  ///
  /// Weights (sum 100):
  /// - 10 coins: 35
  /// - 20 coins: 25
  /// - 1 gem: 20
  /// - 2 gems: 12
  /// - 30 coins: 5 (rare)
  /// - 10 gems: 3 (very rare)
  static GiftLoot rollMeta([Random? rng]) {
    final r = (rng ?? _rng).nextInt(100);
    if (r < 35) return const CoinsLoot(10);
    if (r < 60) return const CoinsLoot(20);
    if (r < 80) return const GemsLoot(1);
    if (r < 92) return const GemsLoot(2);
    if (r < 97) return const CoinsLoot(30);
    return const GemsLoot(10);
  }

  static GiftLoot roll(GiftLootPool pool, [Random? rng]) {
    switch (pool) {
      case GiftLootPool.gameplay:
        return rollGameplay(rng);
      case GiftLootPool.meta:
        return rollMeta(rng);
      case GiftLootPool.doubleCoins:
        return const DoubleCoinsLoot();
    }
  }
}
