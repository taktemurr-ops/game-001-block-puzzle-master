import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/block_game.dart';

void main() {
  group('BlockGame', () {
    test('starts with a valid empty board and three available pieces', () {
      final game = BlockGame(random: Random(1));
      expect(game.score, 0);
      expect(game.board.expand((row) => row).every((cell) => !cell), true);
      expect(game.tray.whereType<Piece>().length, 3);
      expect(game.isGameOver, false);
    });

    test('rejects out-of-bounds and overlapping placements', () {
      final game = BlockGame(random: Random(1));
      game.tray[0] = const Piece('two', [Cell(0, 0), Cell(0, 1)]);
      expect(game.place(0, 0, 7), false);
      expect(game.score, 0);
      expect(game.place(0, 0, 0), true);
      game.tray[1] = const Piece('single', [Cell(0, 0)]);
      expect(game.place(1, 0, 0), false);
    });

    test('completed row clears and increases score', () {
      final game = BlockGame(random: Random(1));
      for (var col = 0; col < 7; col++) {
        game.board[2][col] = true;
      }
      game.tray[0] = const Piece('single', [Cell(0, 0)]);
      expect(game.place(0, 2, 7), true);
      expect(game.board[2].every((cell) => !cell), true);
      expect(game.score, 11);
      expect(game.clearedLines, 1);
    });

    test('completed column clears at the same time', () {
      final game = BlockGame(random: Random(1));
      for (var row = 0; row < 7; row++) {
        game.board[row][4] = true;
      }
      game.tray[0] = const Piece('single', [Cell(0, 0)]);
      expect(game.place(0, 7, 4), true);
      expect(List.generate(8, (r) => game.board[r][4]).every((v) => !v), true);
    });

    test('reports loss when no offered piece fits', () {
      final game = BlockGame(random: Random(1));
      for (final row in game.board) {
        for (var c = 0; c < 8; c++) { row[c] = true; }
      }
      expect(game.isGameOver, true);
    });
  });
}
