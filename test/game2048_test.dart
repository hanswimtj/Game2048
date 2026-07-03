import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game_engine.dart';
import 'package:game2048/main.dart';
import 'package:game2048/score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  test('reports tile movement metadata for animations', () {
    final game = Game2048(
      initialBoard: [
        [2, 0, 2, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ],
    );

    final result = game.move(MoveDirection.left);
    final mergedTiles = result.movements.where((move) => move.merged).toList();

    expect(result.changed, isTrue);
    expect(result.spawnedTile, isNotNull);
    expect(mergedTiles, hasLength(2));
    expect(mergedTiles.map((move) => move.value), [2, 2]);
    expect(mergedTiles.map((move) => move.from), [
      const BoardCell(0, 0),
      const BoardCell(0, 2),
    ]);
    expect(mergedTiles.map((move) => move.to), [
      const BoardCell(0, 0),
      const BoardCell(0, 0),
    ]);
  });

  testWidgets('renders the 2048 board', (tester) async {
    await tester.pumpWidget(const Game2048App());

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('分数'), findsOneWidget);
    expect(find.text('最佳'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
  });

  testWidgets('opens the leaderboard from the best score box', (tester) async {
    await tester.pumpWidget(const Game2048App());

    await tester.tap(find.text('最佳'));
    await tester.pumpAndSettle();

    expect(find.text('最佳成绩'), findsOneWidget);
    expect(find.text('还没有成绩'), findsOneWidget);
  });

  test('stores the top ten scores with timestamps', () async {
    final store = ScoreStore();
    final baseTime = DateTime(2026, 7, 3, 10);

    for (var index = 0; index < 12; index++) {
      await store.recordScore(
        gameId: 'game-$index',
        score: index * 10,
        achievedAt: baseTime.add(Duration(minutes: index)),
      );
    }

    final records = await store.load();

    expect(records, hasLength(10));
    expect(records.first.score, 110);
    expect(records.last.score, 20);
    expect(records.first.achievedAt, baseTime.add(const Duration(minutes: 11)));
  });
}
