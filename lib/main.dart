import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_engine.dart';

void main() {
  runApp(const Game2048App());
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f8f83),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final Game2048 _game = Game2048();
  var _bestScore = 0;
  var _winAcknowledged = false;
  MoveResult? _lastMove;
  var _moveSerial = 0;
  var _isAnimating = false;

  void _restart() {
    setState(() {
      _game.reset();
      _lastMove = null;
      _moveSerial++;
      _isAnimating = false;
      _winAcknowledged = false;
    });
  }

  void _move(MoveDirection direction) {
    if (_isAnimating) {
      return;
    }

    final result = _game.move(direction);
    if (!result.changed) {
      return;
    }

    setState(() {
      _bestScore = math.max(_bestScore, _game.score);
      _lastMove = result;
      _moveSerial++;
      _isAnimating = true;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < 120) {
      return;
    }

    if (velocity.dx.abs() > velocity.dy.abs()) {
      _move(velocity.dx > 0 ? MoveDirection.right : MoveDirection.left);
    } else {
      _move(velocity.dy > 0 ? MoveDirection.down : MoveDirection.up);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _move(MoveDirection.left);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _move(MoveDirection.right);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _move(MoveDirection.up);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _move(MoveDirection.down);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final board = _game.board;
    final shouldShowWin =
        _game.hasWon && !_winAcknowledged && !_game.isGameOver && !_isAnimating;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xfff4f5ef),
        body: SafeArea(
          child: Focus(
            autofocus: true,
            onKeyEvent: _handleKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                final availableBoardHeight =
                    constraints.maxHeight - (compact ? 122 : 136);
                final boardSize = math
                    .min(
                      math.min(constraints.maxWidth - 32, 520.0),
                      availableBoardHeight,
                    )
                    .clamp(170.0, 520.0);

                return Center(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Header(
                            score: _game.score,
                            bestScore: _bestScore,
                            onRestart: _restart,
                          ),
                          SizedBox(height: compact ? 16 : 26),
                          SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: Stack(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanEnd: _handlePanEnd,
                                  child: _Board(
                                    board: board,
                                    lastMove: _lastMove,
                                    moveSerial: _moveSerial,
                                    onAnimationFinished: () {
                                      if (!mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _isAnimating = false;
                                      });
                                    },
                                  ),
                                ),
                                if (shouldShowWin)
                                  _StatusOverlay(
                                    title: '2048',
                                    accentColor: const Color(0xff2f8f83),
                                    primaryLabel: '继续',
                                    onPrimary: () {
                                      setState(() {
                                        _winAcknowledged = true;
                                      });
                                    },
                                    secondaryLabel: '重开',
                                    onSecondary: _restart,
                                  ),
                                if (_game.isGameOver && !_isAnimating)
                                  _StatusOverlay(
                                    title: '结束',
                                    accentColor: const Color(0xffb64b45),
                                    primaryLabel: '再来',
                                    onPrimary: _restart,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.bestScore,
    required this.onRestart,
  });

  final int score;
  final int bestScore;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: const Text(
                '2048',
                style: TextStyle(
                  color: Color(0xff26332f),
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
          ),
        ),
        _ScoreBox(label: '分数', value: score),
        const SizedBox(width: 8),
        _ScoreBox(label: '最佳', value: bestScore),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onRestart,
          tooltip: '重开',
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xff26332f),
            foregroundColor: Colors.white,
            fixedSize: const Size.square(48),
          ),
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xff56635f),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xffd6ddd2),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatefulWidget {
  const _Board({
    required this.board,
    required this.lastMove,
    required this.moveSerial,
    required this.onAnimationFinished,
  });

  final List<List<int>> board;
  final MoveResult? lastMove;
  final int moveSerial;
  final VoidCallback onAnimationFinished;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> with SingleTickerProviderStateMixin {
  static const _padding = 10.0;
  static const _gap = 10.0;
  static const _popStart = 0.58;
  static const _slideEnd = 0.68;

  late final AnimationController _controller;
  MoveResult? _activeMove;
  var _seenMoveSerial = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 245),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed) {
            return;
          }
          widget.onAnimationFinished();
        });
  }

  @override
  void didUpdateWidget(covariant _Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.moveSerial == _seenMoveSerial) {
      return;
    }

    _seenMoveSerial = widget.moveSerial;
    final move = widget.lastMove;
    if (move != null && move.changed) {
      _activeMove = move;
      _controller.forward(from: 0);
    } else {
      _activeMove = null;
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff87918a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileSize =
              (constraints.maxWidth -
                  _padding * 2 -
                  _gap * (Game2048.size - 1)) /
              Game2048.size;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final activeMove = _activeMove;
              return Stack(
                children: [
                  for (var row = 0; row < Game2048.size; row++)
                    for (var col = 0; col < Game2048.size; col++)
                      _PositionedTile(
                        key: ValueKey('background-$row-$col'),
                        offset: _cellOffset(row, col, tileSize),
                        size: tileSize,
                        child: const _Tile(value: 0),
                      ),
                  if (activeMove == null)
                    ..._buildSettledTiles(tileSize)
                  else
                    ..._buildAnimatedTiles(activeMove, tileSize),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildSettledTiles(double tileSize) {
    final tiles = <Widget>[];
    for (var row = 0; row < Game2048.size; row++) {
      for (var col = 0; col < Game2048.size; col++) {
        final value = widget.board[row][col];
        if (value == 0) {
          continue;
        }

        tiles.add(
          _PositionedTile(
            key: ValueKey('settled-$row-$col-$value'),
            offset: _cellOffset(row, col, tileSize),
            size: tileSize,
            child: _Tile(value: value),
          ),
        );
      }
    }
    return tiles;
  }

  List<Widget> _buildAnimatedTiles(MoveResult move, double tileSize) {
    final tiles = <Widget>[];
    final slideProgress = Curves.easeOutCubic.transform(
      (_controller.value / _slideEnd).clamp(0.0, 1.0),
    );
    final hiddenCells = <BoardCell>{
      for (final movement in move.movements)
        if (slideProgress < 1 || movement.merged) movement.to,
      if (move.spawnedTile != null) move.spawnedTile!.cell,
    };

    for (var row = 0; row < Game2048.size; row++) {
      for (var col = 0; col < Game2048.size; col++) {
        final value = widget.board[row][col];
        final cell = BoardCell(row, col);
        if (value == 0 || hiddenCells.contains(cell)) {
          continue;
        }

        tiles.add(
          _PositionedTile(
            key: ValueKey('carried-$row-$col-$value'),
            offset: _cellOffset(row, col, tileSize),
            size: tileSize,
            child: _Tile(value: value),
          ),
        );
      }
    }

    if (slideProgress < 1) {
      for (var index = 0; index < move.movements.length; index++) {
        final movement = move.movements[index];
        final from = _cellOffset(
          movement.from.row,
          movement.from.col,
          tileSize,
        );
        final to = _cellOffset(movement.to.row, movement.to.col, tileSize);
        final mergeFade =
            ((_controller.value - _popStart) / (_slideEnd - _popStart)).clamp(
              0.0,
              1.0,
            );
        final opacity = movement.merged ? 1 - mergeFade : 1.0;
        tiles.add(
          _PositionedTile(
            key: ValueKey(
              'moving-$index-${movement.from.row}-${movement.from.col}'
              '-${movement.to.row}-${movement.to.col}-${movement.value}',
            ),
            offset: Offset.lerp(from, to, slideProgress)!,
            size: tileSize,
            child: Opacity(
              opacity: opacity,
              child: _Tile(value: movement.value),
            ),
          ),
        );
      }
    }

    final popProgress = Curves.easeOutBack.transform(
      ((_controller.value - _popStart) / (1 - _popStart)).clamp(0.0, 1.0),
    );
    if (_controller.value >= _popStart) {
      final popCells = <BoardCell>{
        for (final movement in move.movements)
          if (movement.merged) movement.to,
        if (move.spawnedTile != null) move.spawnedTile!.cell,
      };

      for (final cell in popCells) {
        final value = widget.board[cell.row][cell.col];
        if (value == 0) {
          continue;
        }

        final isSpawned = move.spawnedTile?.cell == cell;
        final scale = isSpawned
            ? (0.25 + popProgress * 0.75)
            : (0.78 + popProgress * 0.22);
        tiles.add(
          _PositionedTile(
            key: ValueKey('pop-${cell.row}-${cell.col}-$value'),
            offset: _cellOffset(cell.row, cell.col, tileSize),
            size: tileSize,
            child: Transform.scale(
              scale: scale,
              child: _Tile(value: value),
            ),
          ),
        );
      }
    }

    return tiles;
  }

  Offset _cellOffset(int row, int col, double tileSize) {
    return Offset(
      _padding + col * (tileSize + _gap),
      _padding + row * (tileSize + _gap),
    );
  }
}

class _PositionedTile extends StatelessWidget {
  const _PositionedTile({
    super.key,
    required this.offset,
    required this.size,
    required this.child,
  });

  final Offset offset;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: size,
      height: size,
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final empty = value == 0;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _tileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: empty
          ? const SizedBox.shrink()
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$value',
                  maxLines: 1,
                  style: TextStyle(
                    color: value <= 4 ? const Color(0xff26332f) : Colors.white,
                    fontSize: value < 1000 ? 34 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }

  Color _tileColor(int value) {
    return switch (value) {
      0 => const Color(0xffaab2ab),
      2 => const Color(0xffe8ded0),
      4 => const Color(0xffdacbb5),
      8 => const Color(0xffe59b58),
      16 => const Color(0xffda754f),
      32 => const Color(0xffc95750),
      64 => const Color(0xffad3f45),
      128 => const Color(0xff6aa19a),
      256 => const Color(0xff4d8f84),
      512 => const Color(0xff2f766f),
      1024 => const Color(0xff385c7a),
      2048 => const Color(0xff26332f),
      _ => const Color(0xff171f1d),
    };
  }
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({
    required this.title,
    required this.accentColor,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final Color accentColor;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xeef4f5ef),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      fixedSize: const Size(104, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(primaryLabel),
                  ),
                  if (secondaryLabel != null && onSecondary != null)
                    OutlinedButton(
                      onPressed: onSecondary,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff26332f),
                        fixedSize: const Size(104, 44),
                        side: const BorderSide(color: Color(0xff87918a)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(secondaryLabel!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
