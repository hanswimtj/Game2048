import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game_engine.dart';
import 'package:game2048/main.dart';

void main() {
  test('merges matching tiles once per move', () {
    final game = Game2048(
      initialBoard: [
        [2, 2, 2, 0],
        [4, 0, 4, 0],
        [8, 8, 8, 8],
        [16, 32, 64, 128],
      ],
    );

    final result = game.move(MoveDirection.left);
    final board = game.board;

    expect(result.changed, isTrue);
    expect(result.gained, 44);
    expect(game.score, 44);
    expect(board[0].take(2), [4, 2]);
    expect(board[1].take(1), [8]);
    expect(board[2].take(2), [16, 16]);
  });

  test('detects a locked board', () {
    final game = Game2048(
      initialBoard: [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ],
    );

    expect(game.isGameOver, isTrue);
    expect(game.move(MoveDirection.left).changed, isFalse);
  });

  testWidgets('renders the 2048 board', (tester) async {
    await tester.pumpWidget(const Game2048App());

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('分数'), findsOneWidget);
    expect(find.text('最佳'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });
}
