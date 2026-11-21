import 'dart:async';

import 'package:flutter/material.dart';

import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/game_rules.dart';
import 'block_engine.dart';
import 'rules.dart';

/// Block Puzzle play screen: drag & drop (or tap-to-place), live preview,
/// line-clear highlight, boosters (hint, undo, hammer, refresh, rotate),
/// timer / move limit / bombs, resume after app kill.
class BlockView extends StatefulWidget {
  final PlayContext ctx;
  const BlockView({super.key, required this.ctx});

  @override
  State<BlockView> createState() => _BlockViewState();
}

class _BlockViewState extends State<BlockView> {
  late BlockGame game;
  late BlockLevel level;
  final GlobalKey _boardKey = GlobalKey();
  int? _selected;
  int? _hoverX, _hoverY, _hoverTray;
  bool _hammer = false;
  Set<int> _flash = {};
  Move? _hint;
  int _seconds = 0;
  int _hints = 0;
  int _undos = 0;
  Timer? _timer;
  bool _ended = false;
  bool _paused = false;

  PlayContext get ctx => widget.ctx;

  bool get _isEndless =>
      level.goal.target == 0; // endless, time attack and zen

  @override
  void initState() {
    super.initState();
    level = BlockRules().finalize(ctx.generated as GeneratedLevel<BlockLevel>);
    final snap = ctx.resume['snap'];
    game = snap is String ? BlockGame.restore(level, snap) : BlockGame(level);
    _seconds = (ctx.resume['secs'] as num?)?.toInt() ?? 0;
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_ended || _paused || !mounted) return;
    setState(() => _seconds++);
    if (level.timeLimit > 0 && _seconds >= level.timeLimit) {
      _onTimeUp();
    }
  }

  int get _timeLeft => level.timeLimit == 0 ? -1 : (level.timeLimit - _seconds).clamp(0, 1 << 20);

  void _persist() {
    ctx.saveResume({'snap': game.serialize(), 'secs': _seconds, 'hints': _hints});
  }

  // ---- Placement -----------------------------------------------------------
  void _place(int tray, int x, int y) {
    final p = game.tray[tray];
    if (p == null || !game.canPlace(p, x, y)) {
      ctx.sfx(Sfx.error);
      return;
    }
    final clearing = game.wouldClear(p, x, y);
    final r = game.place(tray, x, y);
    _selected = null;
    _hint = null;
    if (r.lines > 0) {
      ctx.sfx(game.combo > 1 ? Sfx.combo : Sfx.clear);
      if (!ctx.reducedMotion) {
        final cells = <int>{};
        for (final line in clearing) {
          cells.addAll(game.cellsOfLine(line));
        }
        _flash = cells;
        Future<void>.delayed(const Duration(milliseconds: 260), () {
          if (mounted) setState(() => _flash = {});
        });
      }
    } else {
      ctx.sfx(Sfx.place);
    }
    setState(() {});
    _persist();
    _checkEnd();
  }

  Future<void> _checkEnd() async {
    if (_ended) return;
    if (game.won) {
      _end(true);
      return;
    }
    if (game.lost) {
      if (_isEndless) {
        _end(true);
        return;
      }
      _paused = true;
      final again = await ctx.requestContinue();
      _paused = false;
      if (!mounted) return;
      if (again) {
        setState(game.rescue);
        _persist();
      } else {
        _end(false);
      }
    }
  }

  void _onTimeUp() {
    if (_ended) return;
    if (_isEndless) {
      _end(true);
    } else {
      _end(game.won);
    }
  }

  void _end(bool won) {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    final stars = _isEndless ? BlockRules.endlessStars(game.score) : BlockRules.stars(game);
    ctx.finish(RoundResult(
      won: won && (!_isEndless || game.score > 0),
      score: game.score,
      stars: won ? (stars == 0 && !_isEndless ? 1 : stars) : 0,
      seconds: _seconds,
      moves: game.moves,
      hintsUsed: _hints,
      undosUsed: _undos,
      gameStats: {
        'lines_cleared': game.lines,
        'combos': game.bestCombo,
        'gems_collected': game.gemsCollected,
        'blocks_placed': game.moves,
      },
    ));
  }

  // ---- Boosters --------------------------------------------------------------
  Future<void> _useHint() async {
    if (!await ctx.requestHint()) return;
    _hints++;
    setState(() => _hint = game.bestMove());
  }

  void _undo() {
    if (!game.canUndo) return;
    setState(() {
      game.undo();
      _undos++;
    });
    _persist();
  }

  Future<void> _refresh() async {
    if (!await ctx.requestBooster()) return;
    setState(game.refreshTray);
    _persist();
  }

  Future<void> _toggleHammer() async {
    if (_hammer) {
      setState(() => _hammer = false);
      return;
    }
    if (!await ctx.requestBooster()) return;
    setState(() => _hammer = true);
  }

  // ---- Input mapping -----------------------------------------------------------
  (int, int)? _cellAt(Offset global, BlockPiece? p, {bool fromDrag = false}) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final c = box.size.width / game.size;
    if (fromDrag && p != null) {
      final x = (local.dx / c).round();
      final y = (local.dy / c).round();
      return (x, y);
    }
    final x = (local.dx / c).floor();
    final y = (local.dy / c).floor();
    if (x < 0 || y < 0 || x >= game.size || y >= game.size) return null;
    return (x, y);
  }

  void _onBoardTap(TapUpDetails d) {
    final cell = _cellAt(d.globalPosition, null);
    if (cell == null) return;
    if (_hammer) {
      if (game.hammer(cell.$1, cell.$2)) {
        ctx.sfx(Sfx.clear);
        setState(() => _hammer = false);
        _persist();
      }
      return;
    }
    final sel = _selected;
    if (sel != null) {
      final p = game.tray[sel];
      if (p == null) return;
      final a = _anchorCovering(p, cell.$1, cell.$2);
      _place(sel, a.$1, a.$2);
    }
  }

  /// Tap placement: the tapped cell may be *any* cell of the piece (not only
  /// its top-left), so tapping the bottom row or right column works too.
  (int, int) _anchorCovering(BlockPiece p, int tx, int ty) {
    for (final c in p.cells) {
      final x = tx - c[0], y = ty - c[1];
      if (game.canPlace(p, x, y)) return (x, y);
    }
    return (tx, ty);
  }

  /// Drag placement: if the exact cell under the piece does not fit, snap to
  /// the nearest fitting position within one cell (edges, small finger drift).
  (int, int)? _snap(BlockPiece p, (int, int)? c) {
    if (c == null) return null;
    if (game.canPlace(p, c.$1, c.$2)) return c;
    const order = [(0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, 1), (1, -1), (-1, -1)];
    for (final d in order) {
      final x = c.$1 + d.$1, y = c.$2 + d.$2;
      if (game.canPlace(p, x, y)) return (x, y);
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final t = ctx.t;
    return LayoutBuilder(builder: (context, cons) {
      final boardSize = (cons.maxWidth - 24).clamp(200.0, (cons.maxHeight * 0.58).clamp(200.0, 720.0));
      final cell = boardSize / game.size;
      // The whole play area is the drop target: the dragged piece is drawn
      // above the finger, so when aiming at the bottom rows the finger is
      // below the board. Only the board was a target before, which made
      // pieces impossible to drop on the lower rows.
      return DragTarget<int>(
            onMove: (d) {
              final p = game.tray[d.data];
              if (p == null) return;
              final topLeft = d.offset + _feedbackShift(p, cell);
              final c = _snap(p, _cellAt(topLeft, p, fromDrag: true));
              setState(() {
                _hoverTray = d.data;
                _hoverX = c?.$1;
                _hoverY = c?.$2;
              });
            },
            onLeave: (_) => setState(() => _hoverTray = null),
            onAcceptWithDetails: (d) {
              final x = _hoverX, y = _hoverY;
              setState(() => _hoverTray = null);
              if (x != null && y != null) _place(d.data, x, y);
            },
            builder: (c, _, __) => Column(children: [
        _hud(t),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
              onTapUp: _onBoardTap,
              child: Semantics(
                label: 'board',
                child: SizedBox(
                  key: _boardKey,
                  width: boardSize,
                  height: boardSize,
                  child: CustomPaint(
                    painter: _BoardPainter(
                      game: game,
                      colors: ctx.pieceColors,
                      colorBlind: ctx.colorBlind,
                      preview: _previewCells(),
                      previewOk: _previewOk(),
                      clearing: _previewClear(),
                      flash: _flash,
                      hint: _hint,
                      symbol: ctx.symbol,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Expanded(child: _tray(cell)),
        _boosters(t),
      ]),
      );
    });
  }

  Offset _feedbackShift(BlockPiece p, double cell) =>
      Offset(-p.width * cell / 2, -p.height * cell - 48);

  Set<int> _previewCells() {
    final tr = _hoverTray ?? -1;
    if (tr < 0 || _hoverX == null || _hoverY == null) return {};
    final p = game.tray[tr];
    if (p == null) return {};
    return {
      for (final c in p.cells)
        if (_hoverX! + c[0] >= 0 && _hoverY! + c[1] >= 0 && _hoverX! + c[0] < game.size && _hoverY! + c[1] < game.size)
          game.idx(_hoverX! + c[0], _hoverY! + c[1])
    };
  }

  bool _previewOk() {
    final tr = _hoverTray ?? -1;
    if (tr < 0 || _hoverX == null || _hoverY == null) return false;
    final p = game.tray[tr];
    return p != null && game.canPlace(p, _hoverX!, _hoverY!);
  }

  Set<int> _previewClear() {
    if (!_previewOk()) return {};
    final p = game.tray[_hoverTray!]!;
    final lines = game.wouldClear(p, _hoverX!, _hoverY!);
    final out = <int>{};
    for (final line in lines) {
      out.addAll(game.cellsOfLine(line));
    }
    return out;
  }

  Widget _hud(String Function(String, [Map<String, Object>]) t) {
    final goal = level.goal;
    final goalText = switch (goal.type) {
      GoalType.score => '${t('score')} ${game.score}${goal.target > 0 ? ' / ${goal.target}' : ''}',
      GoalType.lines => '${ctx.lang == 'tr' ? 'Satır' : 'Lines'} ${game.lines} / ${goal.target}',
      GoalType.gems => '💎 ${game.gemsCollected} / ${goal.target}',
      GoalType.survive => '${t('moves')} ${game.moves} / ${goal.target}',
    };
    final chips = <Widget>[
      _chip(Icons.flag, goalText),
      if (game.movesLeft >= 0) _chip(Icons.swipe, '${t('moves_left')}: ${game.movesLeft}'),
      if (_timeLeft >= 0) _chip(Icons.timer, '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}'),
      if (_isEndless) _chip(Icons.star, '${t('score')}: ${game.score}'),
      if (game.combo > 1) _chip(Icons.local_fire_department, 'x${game.combo}'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: chips),
    );
  }

  Widget _chip(IconData i, String text) => Chip(
        avatar: Icon(i, size: 16),
        label: Text(text),
        visualDensity: VisualDensity.compact,
      );

  Widget _tray(double boardCell) {
    final cell = (boardCell * 0.62).clamp(14.0, 34.0);
    final order = ctx.leftHanded ? [2, 1, 0] : [0, 1, 2];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final i in order)
          Expanded(
            child: Center(
              child: game.tray[i] == null
                  ? const SizedBox.shrink()
                  : _trayPiece(i, game.tray[i]!, cell, boardCell),
            ),
          ),
      ],
    );
  }

  Widget _trayPiece(int i, BlockPiece p, double cell, double boardCell) {
    final fits = game.fitsAnywhere(p);
    final piece = Opacity(
      opacity: fits ? 1 : 0.35,
      child: _PieceWidget(piece: p, cell: cell, colors: ctx.pieceColors, selected: _selected == i,
          colorBlind: ctx.colorBlind, symbol: ctx.symbol, hinted: _hint?.tray == i),
    );
    return Semantics(
      button: true,
      label: 'piece ${p.size}',
      child: GestureDetector(
        onTap: () => setState(() => _selected = _selected == i ? null : i),
        onLongPress: () => setState(() => game.rotate(i)),
        child: Draggable<int>(
          data: i,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Transform.translate(
            offset: _feedbackShift(p, boardCell),
            child: _PieceWidget(piece: p, cell: boardCell, colors: ctx.pieceColors, selected: false,
                colorBlind: ctx.colorBlind, symbol: ctx.symbol, hinted: false),
          ),
          childWhenDragging: Opacity(opacity: 0.2, child: piece),
          child: piece,
        ),
      ),
    );
  }

  Widget _boosters(String Function(String, [Map<String, Object>]) t) {
    Widget b(IconData i, String label, VoidCallback? on, {bool active = false}) =>
        IconButton.filledTonal(
          isSelected: active,
          onPressed: on,
          icon: Icon(i),
          tooltip: label,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        b(Icons.lightbulb, t('hint'), _useHint),
        b(Icons.undo, t('undo'), game.canUndo ? _undo : null),
        b(Icons.gavel, 'Hammer', _toggleHammer, active: _hammer),
        b(Icons.autorenew, 'Refresh', _refresh),
        b(Icons.rotate_right, 'Rotate', _selected == null ? null : () => setState(() => game.rotate(_selected!))),
      ]),
    );
  }
}

class _PieceWidget extends StatelessWidget {
  final BlockPiece piece;
  final double cell;
  final List<Color> colors;
  final bool selected;
  final bool colorBlind;
  final bool hinted;
  final String Function(int) symbol;

  const _PieceWidget({
    required this.piece,
    required this.cell,
    required this.colors,
    required this.selected,
    required this.colorBlind,
    required this.symbol,
    required this.hinted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
            color: selected ? Colors.white : (hinted ? Colors.yellowAccent : Colors.transparent), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: piece.width * cell,
        height: piece.height * cell,
        child: Stack(children: [
          for (final c in piece.cells)
            Positioned(
              left: c[0] * cell,
              top: c[1] * cell,
              width: cell,
              height: cell,
              child: _BlockTile(color: colors[(piece.color - 1) % colors.length],
                  label: colorBlind ? symbol(piece.color - 1) : null),
            ),
        ]),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final Color color;
  final String? label;
  const _BlockTile({required this.color, this.label});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 1)],
        ),
        alignment: Alignment.center,
        child: label == null
            ? null
            : FittedBox(child: Text(label!, style: const TextStyle(color: Colors.white))),
      );
}

class _BoardPainter extends CustomPainter {
  final BlockGame game;
  final List<Color> colors;
  final bool colorBlind;
  final Set<int> preview;
  final bool previewOk;
  final Set<int> clearing;
  final Set<int> flash;
  final Move? hint;
  final String Function(int) symbol;

  _BoardPainter({
    required this.game,
    required this.colors,
    required this.colorBlind,
    required this.preview,
    required this.previewOk,
    required this.clearing,
    required this.flash,
    required this.hint,
    required this.symbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = game.size;
    final c = size.width / n;
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)), bg);
    final box = game.level.box;
    if (box > 0) {
      // Block Sudoku: checkerboard tint marks the 3x3 boxes.
      final tint = Paint()..color = Colors.white.withValues(alpha: 0.06);
      for (var by = 0; by < n; by += box) {
        for (var bx = 0; bx < n; bx += box) {
          if (((bx + by) ~/ box).isOdd) {
            canvas.drawRect(Rect.fromLTWH(bx * c, by * c, box * c, box * c), tint);
          }
        }
      }
    }
    final empty = Paint()..color = Colors.white.withValues(alpha: 0.08);
    Set<int> hintCells = {};
    final h = hint;
    if (h != null) {
      final p = game.tray[h.tray];
      if (p != null) hintCells = {for (final e in p.cells) game.idx(h.x + e[0], h.y + e[1])};
    }
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final i = game.idx(x, y);
        final r = RRect.fromRectAndRadius(
            Rect.fromLTWH(x * c + 1.5, y * c + 1.5, c - 3, c - 3), Radius.circular(c * 0.15));
        final v = game.cells[i];
        if (v == Cell.empty) {
          canvas.drawRRect(r, empty);
        } else if (v == Cell.stone) {
          canvas.drawRRect(r, Paint()..color = const Color(0xFF6B6B6B));
          canvas.drawLine(r.outerRect.topLeft + Offset(c * .25, c * .3), r.outerRect.center, Paint()..color = Colors.black38..strokeWidth = 2);
        } else if (v == Cell.ice2 || v == Cell.ice1) {
          canvas.drawRRect(r, Paint()..color = v == Cell.ice2 ? const Color(0xFFB3E5FC) : const Color(0xFFE1F5FE));
          canvas.drawRRect(r, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
        } else {
          final col = colors[(v - 1) % colors.length];
          canvas.drawRRect(r, Paint()..color = col);
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(x * c + 4, y * c + 4, c - 8, (c - 8) * 0.35), Radius.circular(c * 0.1)),
              Paint()..color = Colors.white.withValues(alpha: 0.25));
          if (colorBlind) _text(canvas, symbol(v - 1), Offset(x * c + c / 2, y * c + c / 2), c * 0.45, Colors.white);
        }
        if (game.gems.contains(i)) {
          _text(canvas, '💎', Offset(x * c + c / 2, y * c + c / 2), c * 0.5, Colors.white);
        }
        final bomb = game.bombs[i];
        if (bomb != null) {
          canvas.drawCircle(Offset(x * c + c / 2, y * c + c / 2), c * 0.32, Paint()..color = Colors.black87);
          _text(canvas, '$bomb', Offset(x * c + c / 2, y * c + c / 2), c * 0.32, Colors.redAccent);
        }
        if (clearing.contains(i) || flash.contains(i)) {
          canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: flash.contains(i) ? 0.85 : 0.35));
        }
        if (preview.contains(i)) {
          canvas.drawRRect(
              r, Paint()..color = (previewOk ? Colors.white : Colors.redAccent).withValues(alpha: 0.45));
        }
        if (hintCells.contains(i)) {
          canvas.drawRRect(r, Paint()..color = Colors.yellowAccent..style = PaintingStyle.stroke..strokeWidth = 3);
        }
      }
    }
  }

  void _text(Canvas canvas, String s, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
