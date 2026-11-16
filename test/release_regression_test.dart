import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/block_game.dart';

void main() {
  group('release regression: board rules', () {
    test('simultaneous row and column clearing counts both lines', () {
      final game = BlockGame(random: Random(4));
      for (var i = 0; i < BlockGame.size; i++) {
        if (i != 3) {
          game.board[3][i] = true;
          game.board[i][3] = true;
        }
      }
      game.tray[0] = const Piece('single', [Cell(0, 0)]);
      expect(game.place(0, 3, 3), isTrue);
      expect(game.clearedLines, 2);
      expect(game.score, 41);
      expect(game.board[3].every((filled) => !filled), isTrue);
      expect(List.generate(8, (i) => game.board[i][3]).every((v) => !v), isTrue);
    });

    test('suggestion is legal and does not mutate board or counters', () {
      final game = BlockGame(random: Random(5));
      final before = game.board.map((r) => List<bool>.from(r)).toList();
      final suggestion = game.suggestedMove;
      expect(suggestion, isNotNull);
      expect(game.canPlace(game.tray[suggestion!.trayIndex]!,
          suggestion.row, suggestion.column), isTrue);
      expect(game.board, before);
      expect(game.score, 0);
      expect(game.placed, 0);
    });

    test('failed moves do not create undo history', () {
      final game = BlockGame(random: Random(6));
      game.tray[0] = const Piece('square', [
        Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)
      ]);
      expect(game.place(0, 7, 7), isFalse);
      expect(game.canUndo, isFalse);
      expect(game.score, 0);
    });

    test('undo restores line clear and its score', () {
      final game = BlockGame(random: Random(7));
      for (var col = 0; col < 7; col++) {
        game.board[0][col] = true;
      }
      game.tray[0] = const Piece('single', [Cell(0, 0)]);
      expect(game.place(0, 0, 7), isTrue);
      expect(game.clearedLines, 1);
      expect(game.undo(), isTrue);
      expect(game.clearedLines, 0);
      expect(game.score, 0);
      expect(game.board[0].where((v) => v).length, 7);
      expect(game.tray[0]?.id, 'single');
    });
  });
}
