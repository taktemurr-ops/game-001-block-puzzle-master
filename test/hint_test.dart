import 'package:flutter_test/flutter_test.dart';
import 'package:game_001_block_puzzle_master/game/block_game.dart';

void main() {
  test('hint returns a legal move without changing board or score', () {
    final game = BlockGame();
    final before = game.board.map((row) => List<bool>.from(row)).toList();
    final score = game.score;
    final move = game.suggestedMove;
    expect(move, isNotNull);
    expect(game.canPlace(game.tray[move!.trayIndex]!, move.row, move.column), isTrue);
    expect(game.score, score);
    for (var row = 0; row < BlockGame.size; row++) {
      expect(game.board[row], before[row]);
    }
  });

  test('hint is absent when no legal placement remains', () {
    final game = BlockGame();
    for (final row in game.board) {
      row.fillRange(0, BlockGame.size, true);
    }
    expect(game.suggestedMove, isNull);
    expect(game.isGameOver, isTrue);
  });
}
