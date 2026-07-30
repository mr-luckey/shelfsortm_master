# ShelfSort Master

Replica of [Goods Puzzle: Sort Challenge™](https://play.google.com/store/apps/details?id=com.fc.goods.sort.matching.puzzle.triplemaster&hl=en).

## Deep-analyzed rules (exact)

1. **Depth stacks** — each shelf column has a front good + hidden goods behind  
2. **Only fronts are playable** — tap/drag front → **empty column only**  
3. **Match 3 fronts** on one shelf → clear; behind goods **slide forward**  
4. **Empty columns** = working space; fill every front → **lose (locked)**  
5. **Timer** + Freeze / Refresh / Hammer / Extra shelf  
6. **Irregular cabinet layout** + mono color theme per level  
7. Gameplay = **BLoC** (no `setState`)

Emoji goods stand in for 3D bottles.

## Run

```bash
flutter pub get
flutter run
```

Hot restart (`R`) after this rewrite. Play **level 3+** to see hidden-behind peeks.
