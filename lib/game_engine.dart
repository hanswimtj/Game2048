import 'dart:math';

enum MoveDirection { up, down, left, right }

class MoveResult {
  const MoveResult({
    required this.changed,
    required this.gained,
    required this.won,
    required this.gameOver,
    this.movements = const [],
    this.spawnedTile,
  });

  final bool changed;
  final int gained;
  final bool won;
  final bool gameOver;
  final List<TileMovement> movements;
  final SpawnedTile? spawnedTile;
}

class BoardCell {
  const BoardCell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is BoardCell && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class TileMovement {
  const TileMovement({
    required this.value,
    required this.from,
    required this.to,
    required this.merged,
  });

  final int value;
  final BoardCell from;
  final BoardCell to;
  final bool merged;
}

class SpawnedTile {
  const SpawnedTile({required this.value, required this.cell});

  final int value;
  final BoardCell cell;
}

class Game2048 {
  Game2048({Random? random, List<List<int>>? initialBoard, this.score = 0})
    : _random = random ?? Random() {
    if (initialBoard == null) {
      reset();
    } else {
      _board = _copyBoard(initialBoard);
      hasWon = _board.any((row) => row.any((value) => value >= 2048));
    }
  }

  static const int size = 4;

  final Random _random;
  late List<List<int>> _board;
  int score;
  bool hasWon = false;

  List<List<int>> get board => _copyBoard(_board);

  bool get isGameOver {
    if (_emptyCells().isNotEmpty) {
      return false;
    }

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final value = _board[row][col];
        if (row + 1 < size && _board[row + 1][col] == value) {
          return false;
        }
        if (col + 1 < size && _board[row][col + 1] == value) {
          return false;
        }
      }
    }

    return true;
  }

  void reset() {
    _board = List.generate(size, (_) => List<int>.filled(size, 0));
    score = 0;
    hasWon = false;
    _addRandomTile();
    _addRandomTile();
  }

  MoveResult move(MoveDirection direction) {
    final before = _copyBoard(_board);
    var gained = 0;
    final movements = <TileMovement>[];

    for (var index = 0; index < size; index++) {
      final line = _readLineWithPositions(index, direction);
      final merged = _mergeLine(line, index, direction);
      gained += merged.gained;
      movements.addAll(merged.movements);
      _writeLine(index, direction, merged.values);
    }

    final changed = !_boardsEqual(before, _board);
    SpawnedTile? spawnedTile;
    if (changed) {
      score += gained;
      spawnedTile = _addRandomTile();
      hasWon = hasWon || _board.any((row) => row.any((value) => value >= 2048));
    }

    return MoveResult(
      changed: changed,
      gained: changed ? gained : 0,
      won: hasWon,
      gameOver: isGameOver,
      movements: changed ? movements : const [],
      spawnedTile: spawnedTile,
    );
  }

  List<_LineTile> _readLineWithPositions(int index, MoveDirection direction) {
    switch (direction) {
      case MoveDirection.left:
        return List<_LineTile>.generate(
          size,
          (col) => _LineTile(_board[index][col], col),
        );
      case MoveDirection.right:
        return List<_LineTile>.generate(size, (col) {
          final sourceCol = size - 1 - col;
          return _LineTile(_board[index][sourceCol], col);
        });
      case MoveDirection.up:
        return List<_LineTile>.generate(
          size,
          (row) => _LineTile(_board[row][index], row),
        );
      case MoveDirection.down:
        return List<_LineTile>.generate(size, (row) {
          final sourceRow = size - 1 - row;
          return _LineTile(_board[sourceRow][index], row);
        });
    }
  }

  void _writeLine(int index, MoveDirection direction, List<int> values) {
    switch (direction) {
      case MoveDirection.left:
        _board[index] = List<int>.from(values);
      case MoveDirection.right:
        for (var col = 0; col < size; col++) {
          _board[index][size - 1 - col] = values[col];
        }
      case MoveDirection.up:
        for (var row = 0; row < size; row++) {
          _board[row][index] = values[row];
        }
      case MoveDirection.down:
        for (var row = 0; row < size; row++) {
          _board[size - 1 - row][index] = values[row];
        }
    }
  }

  _MergedLine _mergeLine(
    List<_LineTile> line,
    int index,
    MoveDirection direction,
  ) {
    final compact = line.where((tile) => tile.value != 0).toList();
    final merged = <int>[];
    final movements = <TileMovement>[];
    var gained = 0;
    var cursor = 0;

    while (cursor < compact.length) {
      final tile = compact[cursor];
      final value = tile.value;
      final target = _cellForLineOffset(index, direction, merged.length);

      if (cursor + 1 < compact.length && compact[cursor + 1].value == value) {
        final nextTile = compact[cursor + 1];
        final doubled = value * 2;
        merged.add(doubled);
        movements
          ..add(
            TileMovement(
              value: value,
              from: _cellForLineOffset(index, direction, tile.offset),
              to: target,
              merged: true,
            ),
          )
          ..add(
            TileMovement(
              value: value,
              from: _cellForLineOffset(index, direction, nextTile.offset),
              to: target,
              merged: true,
            ),
          );
        gained += doubled;
        cursor += 2;
      } else {
        merged.add(value);
        movements.add(
          TileMovement(
            value: value,
            from: _cellForLineOffset(index, direction, tile.offset),
            to: target,
            merged: false,
          ),
        );
        cursor++;
      }
    }

    while (merged.length < size) {
      merged.add(0);
    }

    return _MergedLine(merged, gained, movements);
  }

  SpawnedTile? _addRandomTile() {
    final cells = _emptyCells();
    if (cells.isEmpty) {
      return null;
    }

    final cell = cells[_random.nextInt(cells.length)];
    final value = _random.nextDouble() < 0.9 ? 2 : 4;
    _board[cell.row][cell.col] = value;
    return SpawnedTile(value: value, cell: BoardCell(cell.row, cell.col));
  }

  BoardCell _cellForLineOffset(int index, MoveDirection direction, int offset) {
    switch (direction) {
      case MoveDirection.left:
        return BoardCell(index, offset);
      case MoveDirection.right:
        return BoardCell(index, size - 1 - offset);
      case MoveDirection.up:
        return BoardCell(offset, index);
      case MoveDirection.down:
        return BoardCell(size - 1 - offset, index);
    }
  }

  List<_Cell> _emptyCells() {
    final cells = <_Cell>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (_board[row][col] == 0) {
          cells.add(_Cell(row, col));
        }
      }
    }
    return cells;
  }

  static List<List<int>> _copyBoard(List<List<int>> board) {
    return board.map((row) => List<int>.from(row)).toList();
  }

  static bool _boardsEqual(List<List<int>> a, List<List<int>> b) {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (a[row][col] != b[row][col]) {
          return false;
        }
      }
    }
    return true;
  }
}

class _MergedLine {
  const _MergedLine(this.values, this.gained, this.movements);

  final List<int> values;
  final int gained;
  final List<TileMovement> movements;
}

class _LineTile {
  const _LineTile(this.value, this.offset);

  final int value;
  final int offset;
}

class _Cell {
  const _Cell(this.row, this.col);

  final int row;
  final int col;
}
