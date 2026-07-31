import 'toy_item_type.dart';

/// Exact 4×8 grid from reference screenshot (Level 36).
abstract final class PremiumDemoData {
  static const level = 36;
  static const coins = 12450;
  static const gems = 250;

  static const goals = [
    (type: ToyType.teddy, remaining: 12),
    (type: ToyType.duck, remaining: 12),
    (type: ToyType.frog, remaining: 12),
    (type: ToyType.rocket, remaining: 12),
  ];

  static const grid = <List<ToyType>>[
    [ToyType.teddy, ToyType.duck, ToyType.frog, ToyType.rocket],
    [ToyType.rabbit, ToyType.panda, ToyType.cat, ToyType.owl],
    [ToyType.heart, ToyType.football, ToyType.star, ToyType.penguin],
    [ToyType.cactus, ToyType.grapes, ToyType.apple, ToyType.rainbowRings],
    [ToyType.car, ToyType.chick, ToyType.pig, ToyType.whale],
    [ToyType.unicorn, ToyType.dinosaur, ToyType.burger, ToyType.fries],
    [ToyType.sunglasses, ToyType.iceCream, ToyType.dice, ToyType.robot],
    [ToyType.basketball, ToyType.flower, ToyType.octopus, ToyType.bee],
  ];
}
