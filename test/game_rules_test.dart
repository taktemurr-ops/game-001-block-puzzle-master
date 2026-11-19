import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/core/level_plan.dart';
import 'package:game_001_block_puzzle_master/game/block_engine.dart';
import 'package:game_001_block_puzzle_master/game/rules.dart';

void main() {
  final rules = BlockRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  BlockLevel level(int n) => rules.finalize(rules.build(planner.spec(n)));

  test('placement rules: bounds and overlap', () {
    final g = BlockGame(level(1));
    final p = g.tray.firstWhere((e) => e != null)!;
    expect(g.canPlace(p, -1, 0), isFalse);
    expect(g.canPlace(p, g.size, 0), isFalse);
  });

  test('full row clears and scores', () {
    final l = BlockLevel(
      size: 8,
      cells: List.filled(64, 0)..setAll(0, [1, 1, 1, 1, 1, 1, 1, 0]),
      gems: {},
      bombs: {},
      goal: const BlockGoal(GoalType.lines, 1),
      moveLimit: 0,
      timeLimit: 0,
      seed: 1,
      difficulty: 1,
      zen: false,
      aiMoves: 0,
    );
    final g = BlockGame(l);
    g.tray[0] = const BlockPiece(0, [[0, 0]], 3);
    final r = g.place(0, 7, 0);
    expect(r.lines, 1);
    expect(g.cells.take(8).every((c) => c == 0), isTrue);
    expect(g.won, isTrue);
  });

  test('ice needs two clears, gems are collected, bombs explode', () {
    final cells = List.filled(64, 0);
    for (var x = 0; x < 7; x++) {
      cells[x] = 1;
    }
    cells[3] = Cell.ice2;
    final l = BlockLevel(
      size: 8,
      cells: cells,
      gems: {1},
      bombs: {2: 1},
      goal: const BlockGoal(GoalType.gems, 1),
      moveLimit: 0,
      timeLimit: 0,
      seed: 1,
      difficulty: 1,
      zen: false,
      aiMoves: 0,
    );
    final g = BlockGame(l);
    g.tray[0] = const BlockPiece(0, [[0, 0]], 3);
    g.place(0, 7, 0);
    expect(g.cells[3], Cell.ice1);
    expect(g.gemsCollected, 1);
    expect(g.exploded, isFalse, reason: 'bomb cleared on the same move');
  });

  test('undo restores the exact state', () {
    final g = BlockGame(level(30));
    final before = g.serialize();
    final m = g.bestMove()!;
    g.place(m.tray, m.x, m.y);
    g.undo();
    expect(g.serialize(), before);
  });

  test('save/resume mid-level reproduces the piece stream', () {
    final l = level(55);
    final g = BlockGame(l);
    for (var i = 0; i < 5; i++) {
      final m = g.bestMove();
      if (m == null) break;
      g.place(m.tray, m.x, m.y);
    }
    final restored = BlockGame.restore(l, g.serialize());
    expect(restored.serialize(), g.serialize());
    final a = g.bestMove(), b = restored.bestMove();
    if (a != null && b != null) {
      g.place(a.tray, a.x, a.y);
      restored.place(b.tray, b.x, b.y);
      expect(restored.serialize(), g.serialize());
    }
  });

  test('zen mode never ends', () {
    final spec = planner.run(GameModeId.zen, 3);
    final g = BlockGame(rules.build(spec).puzzle);
    for (var i = 0; i < 300; i++) {
      final m = g.bestMove();
      expect(m, isNotNull);
      g.place(m!.tray, m.x, m.y);
    }
    expect(g.lost, isFalse);
  });

  test('levels are deterministic', () {
    expect(level(777).cells, equals(level(777).cells));
    expect(level(777).aiMoves, level(777).aiMoves);
  });

  test('starter levels 1..200 are all solvable by the AI (CI runs 1..1000)', () {
    for (var n = 1; n <= 200; n++) {
      final g = rules.build(planner.spec(n));
      expect(g.validation.ok, isTrue, reason: 'level $n');
    }
  });

  test('sampled procedural levels up to 50.000 are solvable', () {
    for (var n = 1000; n <= 50000; n += 2450) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });

  test('all modes and 20 challenges generate', () {
    for (final m in rules.modes) {
      final spec = m == GameModeId.campaign ? planner.spec(5) : planner.run(m, 1);
      expect(rules.build(spec).validation.ok, isTrue, reason: m.name);
    }
    for (var c = 1; c <= 20; c++) {
      expect(rules.build(planner.challenge(c)).validation.ok, isTrue);
    }
  });
}
