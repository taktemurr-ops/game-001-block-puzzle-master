import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/adventure_config.dart';
import 'package:game_001_block_puzzle_master/game/block_engine.dart';
import 'package:game_001_block_puzzle_master/game/picture_art.dart';
import 'package:game_001_block_puzzle_master/game/rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

/// Blok Macerası: gizli resim açma kipi.
void main() {
  final rules = blokMacerasiConfig.rules as BlockRules;
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('33 dilde ad, slogan ve anlatım; 100.000 bölüm', () {
    expect(blokMacerasiConfig.title.length, 33);
    expect(blokMacerasiConfig.tagline.length, 33);
    for (final s in blokMacerasiConfig.tutorial) {
      expect(s.text.length, 33);
    }
    expect(rules.levelCount, 100000);
    expect(blokMacerasiConfig.gameId, 'oyun-blok-macerasi');
  });

  test('her tema resim üretir', () {
    for (var s = 0; s < 60; s++) {
      final p = blockPicture(8, 1 + s % 10, SeededRandom(s));
      expect(p.length, 64);
      expect(p.where((v) => v > 0).length, greaterThanOrEqualTo(4));
      expect(p.every((v) => v >= 0 && v <= 8), isTrue);
    }
  });

  test('kampanya bölümleri resim hedefli ve yapay zekâ resmi açar', () {
    for (final n in [1, 9, 77, 500, 4321, 33333, 99999]) {
      final g = rules.build(planner.spec(n));
      expect(g.validation.ok, isTrue, reason: 'bölüm $n');
      final l = rules.finalize(g);
      if (l.goal.target == 0) continue;
      expect(l.goal.type, GoalType.picture);
      expect(l.goal.target, l.picture.where((v) => v > 0).length);
      expect(simulateBlockLevel(l), greaterThan(0), reason: 'bölüm $n');
    }
  });

  test('temizlenen satır altındaki resmi açar; kayıt açılanları korur', () {
    final pic = List.filled(64, 0)..setAll(0, [2, 2, 2, 0, 0, 0, 0, 0]);
    final l = BlockLevel(
      size: 8,
      cells: List.filled(64, 0)..setAll(0, [1, 1, 1, 1, 1, 1, 1, 0]),
      gems: {},
      bombs: {},
      goal: const BlockGoal(GoalType.picture, 3),
      moveLimit: 0,
      timeLimit: 0,
      seed: 1,
      difficulty: 1,
      zen: false,
      aiMoves: 0,
      picture: pic,
    );
    final g = BlockGame(l);
    expect(g.won, isFalse);
    g.tray[0] = const BlockPiece(0, [[0, 0]], 3);
    g.place(0, 7, 0);
    expect(g.revealed, {0, 1, 2});
    expect(g.won, isTrue);
    final back = BlockGame.restore(l, g.serialize());
    expect(back.revealed, g.revealed);
  });
}
