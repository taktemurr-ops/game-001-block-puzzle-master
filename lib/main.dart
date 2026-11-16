import 'package:flutter/material.dart';
import 'game/block_game.dart';

void main() => runApp(const BlockPuzzleMaster());

class BlockPuzzleMaster extends StatelessWidget {
  const BlockPuzzleMaster({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Block Puzzle Master',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF52B6F7),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const BlockPuzzleScreen(),
      );
}

class BlockPuzzleScreen extends StatefulWidget {
  const BlockPuzzleScreen({super.key});

  @override
  State<BlockPuzzleScreen> createState() => _BlockPuzzleScreenState();
}

class _BlockPuzzleScreenState extends State<BlockPuzzleScreen> {
  BlockGame game = BlockGame();
  int selectedPiece = 0;
  String notice = 'Choose a shape, then tap an empty board cell.';

  void restart() {
    setState(() {
      game = BlockGame();
      selectedPiece = 0;
      notice = 'New game started';
    });
  }

  void attempt(int row, int col) {
    setState(() {
      final success = game.place(selectedPiece, row, col);
      notice = success ? 'Nice move!' : 'That piece cannot fit there.';
      if (success) {
        final next = game.tray.indexWhere((p) => p != null);
        selectedPiece = next < 0 ? 0 : next;
      }
      if (game.isGameOver) notice = 'Game over — try again!';
    });
  }

  Widget cell(int row, int column) {
    final occupied = game.board[row][column];
    final selected = game.tray[selectedPiece];
    final canDrop = selected != null && game.canPlace(selected, row, column);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            key: ValueKey('cell-$row-$column'),
            onTap: game.isGameOver ? null : () => attempt(row, column),
            borderRadius: BorderRadius.circular(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: occupied
                    ? const Color(0xFF4CC9F0)
                    : canDrop ? const Color(0xFF24564C) : const Color(0xFF253B58),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget pieceCard(int index) {
    final piece = game.tray[index];
    final selected = selectedPiece == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: OutlinedButton(
          key: ValueKey('piece-$index'),
          onPressed: piece == null ? null : () => setState(() => selectedPiece = index),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(8),
            side: BorderSide(
              color: selected ? Colors.cyanAccent : Colors.blueGrey,
              width: selected ? 2 : 1,
            ),
          ),
          child: SizedBox(
            height: 80,
            child: Center(
              child: piece == null
                  ? const Icon(Icons.check_circle_outline)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(piece.id, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 52,
                          child: Builder(builder: (context) {
                            final height = piece.cells.map((c) => c.row).reduce((a, b) => a > b ? a : b) + 1;
                            final width = piece.cells.map((c) => c.column).reduce((a, b) => a > b ? a : b) + 1;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(height, (r) => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(width, (c) {
                                  final filled = piece.cells.any((cell) => cell.row == r && cell.column == c);
                                  return Container(
                                    width: 13,
                                    height: 13,
                                    margin: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: filled ? Colors.lightBlueAccent : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                }),
                              )),
                            );
                          }),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Puzzle Master'),
        actions: [
          IconButton(
            onPressed: restart,
            icon: const Icon(Icons.restart_alt),
            tooltip: 'New game',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SCORE  ${game.score}',
                      key: const ValueKey('score'),
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Placed: ${game.placed}   Lines: ${game.clearedLines}'),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      children: List.generate(
                        BlockGame.size,
                        (r) => Expanded(
                          child: Row(
                            children: List.generate(
                              BlockGame.size,
                              (c) => cell(r, c),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(notice, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(children: List.generate(3, pieceCard)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: game.canUndo ? () => setState(() {
                      game.undo();
                      selectedPiece = game.tray.indexWhere((p) => p != null);
                      if (selectedPiece < 0) selectedPiece = 0;
                      notice = 'Previous move restored.';
                    }) : null,
                    icon: const Icon(Icons.undo),
                    label: const Text('Undo'),
                  ),
                  if (game.isGameOver)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: FilledButton(
                        onPressed: restart,
                        child: const Text('Play again'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
