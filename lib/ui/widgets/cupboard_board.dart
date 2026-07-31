import 'package:flutter/material.dart';

import '../../engine/match_engine.dart';
import '../../models/shelf.dart';
import '../theme/shelf_look.dart';
import 'pixel_shelf.dart';

/// Cupboard — rows share all vertical space; item size fits each slot.
class CupboardBoard extends StatelessWidget {
  final List<List<int>> layout;
  final List<Shelf> shelves;
  final BoardPos? selected;
  final int clearingShelf;
  final int openingShelf;
  final Set<int> finishedShelves;
  final double scale;
  final ShelfLook look;
  final LevelSpice spice;
  final void Function(BoardPos) onTap;
  final void Function(BoardPos, BoardPos) onMove;

  const CupboardBoard({
    super.key,
    required this.layout,
    required this.shelves,
    required this.selected,
    required this.clearingShelf,
    required this.openingShelf,
    required this.finishedShelves,
    required this.scale,
    required this.look,
    required this.spice,
    required this.onTap,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final idToIndex = <int, int>{};
    for (var i = 0; i < shelves.length; i++) {
      idToIndex[shelves[i].shelfId] = i;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Column(
        children: [
          for (var r = 0; r < layout.length; r++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: r < layout.length - 1 ? 6 : 0,
                  left: spice == LevelSpice.staggered && r.isOdd ? 8 : 0,
                  right: spice == LevelSpice.staggered && r.isEven ? 8 : 0,
                ),
                child: LayoutBuilder(
                  builder: (context, rowConstraints) {
                    final row = layout[r];
                    final rowH = rowConstraints.maxHeight;

                    return Row(
                      children: [
                        for (final cell in row)
                          if (cell == 0)
                            Expanded(child: SizedBox(height: rowH))
                          else
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final idx = idToIndex[cell];
                                  if (idx == null) {
                                    return SizedBox(height: rowH);
                                  }
                                  return CabinetShelf(
                                    shelf: shelves[idx],
                                    shelfIndex: idx,
                                    selected: selected,
                                    celebrating: clearingShelf == idx,
                                    opening: openingShelf == idx,
                                    isDone: finishedShelves.contains(idx),
                                    scale: scale,
                                    look: look,
                                    spice: spice,
                                    onTap: onTap,
                                    onMove: onMove,
                                  );
                                },
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
