# ShelfSort Master

Replica of [Goods Puzzle: Sort Challenge™](https://play.google.com/store/apps/details?id=com.fc.goods.sort.matching.puzzle.triplemaster&hl=en) (Falcon-style shelf sorting).

## Exact gameplay

1. Cabinet of **3-slot shelves** filled with mixed goods  
2. **2 empty BUFFER shelves** = working space  
3. **Tap** a good → tap empty slot (or **drag**) to move  
4. **3 identical on one shelf** → auto clear  
5. Clear all before **timer** ends  
6. Boosters: Undo / Freeze / Refresh / Magnet / Extra Shelf  

Emoji goods for now. Gameplay uses **BLoC** (no `setState`).

## Run

```bash
flutter pub get
flutter run
```

Hot restart (`R`) required after this rewrite.
