# Block Puzzle Master

**Game Studio 100 | Puzzle | Android / iOS | Flutter**

## Implemented in the current prototype
- 8×8 interactive block puzzle board
- Three-piece tray with selectable block shapes
- Placement rules with occupied-cell and boundary validation
- Simultaneous full-row/full-column clearing and scoring
- Game-over detection and restart
- Pure Dart rules engine (`lib/game/block_game.dart`)
- Unit tests for core rules (`test/block_game_test.dart`)

**Controls:** Select a piece below the board, then tap an empty cell where its
top-left occupied square should land. This is an early interaction model;
drag-and-drop, visual shape previews, effects, content and polish are future work.

## Getting started

```bash
flutter pub get
flutter test
flutter run
```

A Flutter SDK is required. The code has been committed but has **not** yet
been compiled or device-tested in this ChatGPT session.

## Next steps
1. Drag-and-drop piece placement with correct shape previews.
2. Improve the game-over and refill experience, adding a new game confirmation.
3. Add deterministic level/seed handling and persistent local save.
4. Introduce modes: classic, time attack, daily challenge and zen.
5. Add accessibility, localization and analytics.
6. Integrate consent-aware ads/IAP only after store-policy review.

See `docs/` for the working scope. This is an original implementation, not a
copy of third-party assets, branded layouts or proprietary gameplay code.

## Recent iteration
- Piece tray now previews the actual geometric block shape.
- Available board anchors are highlighted for the selected piece.
- Next: responsive layout and confirmed Flutter CI results.
