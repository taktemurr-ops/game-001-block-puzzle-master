import 'dart:math';

/// Immutable integer coordinate used by the 8x8 placement rules.
class Cell {
  final int row;
  final int column;
  const Cell(this.row, this.column);
}

class Piece {
  final String id;
  final List<Cell> cells;
  const Piece(this.id, this.cells);
}

/// Pure Dart game rules, independent of Flutter widgets.
/// A successful placement clears all completed rows and columns at once.
class BlockGame {
  static const int size = 8;
  static const List<Piece> shapes = [
    Piece('single', [Cell(0, 0)]),
    Piece('two', [Cell(0, 0), Cell(0, 1)]),
    Piece('three', [Cell(0, 0), Cell(0, 1), Cell(0, 2)]),
    Piece('square', [Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)]),
    Piece('corner', [Cell(0, 0), Cell(1, 0), Cell(1, 1)]),
    Piece('vertical', [Cell(0, 0), Cell(1, 0), Cell(2, 0)]),
    Piece('zigzag', [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 2)]),
  ];

  final Random random;
  final List<List<bool>> board =
      List.generate(size, (_) => List<bool>.filled(size, false));
  final List<Piece?> tray = List<Piece?>.filled(3, null);
  int score = 0;
  int placed = 0;
  int clearedLines = 0;

  BlockGame({Random? random}) : random = random ?? Random() {
    refill();
  }

  bool within(int row, int column) =>
      row >= 0 && row < size && column >= 0 && column < size;

  bool canPlace(Piece piece, int row, int column) =>
      piece.cells.every((cell) {
        final r = row + cell.row;
        final c = column + cell.column;
        return within(r, c) && !board[r][c];
      });

  bool place(int trayIndex, int row, int column) {
    if (trayIndex < 0 || trayIndex >= tray.length) return false;
    final piece = tray[trayIndex];
    if (piece == null || !canPlace(piece, row, column)) return false;

    for (final cell in piece.cells) {
      board[row + cell.row][column + cell.column] = true;
    }
    score += piece.cells.length;
    placed++;
    tray[trayIndex] = null;

    final fullRows = <int>[];
    final fullColumns = <int>[];
    for (var r = 0; r < size; r++) {
      if (board[r].every((occupied) => occupied)) fullRows.add(r);
    }
    for (var c = 0; c < size; c++) {
      if (List.generate(size, (r) => board[r][c]).every((occupied) => occupied)) {
        fullColumns.add(c);
      }
    }

    // Clear simultaneously so intersections count as one occupied tile.
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        board[r][c] = false;
      }
    }
    for (final c in fullColumns) {
      for (var r = 0; r < size; r++) {
        board[r][c] = false;
      }
    }
    final lines = fullRows.length + fullColumns.length;
    clearedLines += lines;
    if (lines > 0) score += lines * lines * 10;

    if (tray.every((p) => p == null)) refill();
    return true;
  }

  void refill() {
    for (var index = 0; index < tray.length; index++) {
      tray[index] ??= shapes[random.nextInt(shapes.length)];
    }
  }

  bool get isGameOver {
    for (final piece in tray) {
      if (piece == null) continue;
      for (var row = 0; row < size; row++) {
        for (var column = 0; column < size; column++) {
          if (canPlace(piece, row, column)) return false;
        }
      }
    }
    return true;
  }
}
