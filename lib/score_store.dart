import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ScoreRecord {
  const ScoreRecord({
    required this.id,
    required this.score,
    required this.achievedAt,
  });

  final String id;
  final int score;
  final DateTime achievedAt;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'score': score,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }

  static ScoreRecord? fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }

    final id = value['id'];
    final score = value['score'];
    final achievedAt = value['achievedAt'];
    if (id is! String || score is! int || achievedAt is! String) {
      return null;
    }

    final parsedTime = DateTime.tryParse(achievedAt);
    if (parsedTime == null) {
      return null;
    }

    return ScoreRecord(id: id, score: score, achievedAt: parsedTime);
  }
}

class ScoreStore {
  static const _recordsKey = 'score_records_v1';
  static const _limit = 10;

  Future<List<ScoreRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRecords = prefs.getString(_recordsKey);
    if (rawRecords == null) {
      return <ScoreRecord>[];
    }

    final decoded = jsonDecode(rawRecords);
    if (decoded is! List<Object?>) {
      return <ScoreRecord>[];
    }

    final records = decoded
        .map(ScoreRecord.fromJson)
        .whereType<ScoreRecord>()
        .toList();
    _sort(records);
    return records.take(_limit).toList();
  }

  Future<List<ScoreRecord>> recordScore({
    required String gameId,
    required int score,
    DateTime? achievedAt,
  }) async {
    if (score <= 0) {
      return load();
    }

    final records = await load();
    final existingIndex = records.indexWhere((record) => record.id == gameId);
    final timestamp = achievedAt ?? DateTime.now();

    if (existingIndex >= 0) {
      final existing = records[existingIndex];
      if (score > existing.score) {
        records[existingIndex] = ScoreRecord(
          id: gameId,
          score: score,
          achievedAt: timestamp,
        );
      }
    } else if (records.length < _limit || score > records.last.score) {
      records.add(ScoreRecord(id: gameId, score: score, achievedAt: timestamp));
    }

    _sort(records);
    final trimmed = records.take(_limit).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(trimmed.map((record) => record.toJson()).toList()),
    );
    return trimmed;
  }

  void _sort(List<ScoreRecord> records) {
    records.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      return b.achievedAt.compareTo(a.achievedAt);
    });
  }
}
