import 'dart:math';

enum MoveDirection { up, down, left, right }

class MoveResult {
  const MoveResult({
    required this.changed,
    required this.gained,
    required this.won,
    required this.gameOver,
  });

  final bool changed;
  final int gained;
  final bool won;
  final bool gameOver;
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

    for (var index = 0; index < size; index++) {
      final line = _readLine(index, direction);
      final merged = _mergeLine(line);
      gained += merged.gained;
      _writeLine(index, direction, merged.values);
    }

    final changed = !_boardsEqual(before, _board);
    if (changed) {
      score += gained;
      _addRandomTile();
      hasWon = hasWon || _board.any((row) => row.any((value) => value >= 2048));
    }

    return MoveResult(
      changed: changed,
      gained: changed ? gained : 0,
      won: hasWon,
      gameOver: isGameOver,
    );
  }

  List<int> _readLine(int index, MoveDirection direction) {
    switch (direction) {
      case MoveDirection.left:
        return List<int>.from(_board[index]);
      case MoveDirection.right:
        return List<int>.generate(size, (col) => _board[index][size - 1 - col]);
      case MoveDirection.up:
        return List<int>.generate(size, (row) => _board[row][index]);
      case MoveDirection.down:
        return List<int>.generate(size, (row) => _board[size - 1 - row][index]);
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

  _MergedLine _mergeLine(List<int> line) {
    final compact = line.where((value) => value != 0).toList();
    final merged = <int>[];
    var gained = 0;
    var cursor = 0;

    while (cursor < compact.length) {
      final value = compact[cursor];
      if (cursor + 1 < compact.length && compact[cursor + 1] == value) {
        final doubled = value * 2;
        merged.add(doubled);
        gained += doubled;
        cursor += 2;
      } else {
        merged.add(value);
        cursor++;
      }
    }

    while (merged.length < size) {
      merged.add(0);
    }

    return _MergedLine(merged, gained);
  }

  void _addRandomTile() {
    final cells = _emptyCells();
    if (cells.isEmpty) {
      return;
    }

    final cell = cells[_random.nextInt(cells.length)];
    _board[cell.row][cell.col] = _random.nextDouble() < 0.9 ? 2 : 4;
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
  const _MergedLine(this.values, this.gained);

  final List<int> values;
  final int gained;
}

class _Cell {
  const _Cell(this.row, this.col);

  final int row;
  final int col;
}
