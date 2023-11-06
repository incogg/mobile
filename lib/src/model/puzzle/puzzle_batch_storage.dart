import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:sqflite/sqflite.dart';

import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/db/database.dart';

import 'puzzle.dart';
import 'puzzle_theme.dart';

part 'puzzle_batch_storage.freezed.dart';
part 'puzzle_batch_storage.g.dart';

@Riverpod(keepAlive: true)
PuzzleBatchStorage puzzleBatchStorage(PuzzleBatchStorageRef ref) {
  final database = ref.watch(databaseProvider);
  return PuzzleBatchStorage(database);
}

const _anonUserKey = '**anon**';
const _tableName = 'puzzle_batchs';

/// Local storage for puzzles.
class PuzzleBatchStorage {
  const PuzzleBatchStorage(this._db);

  final Database _db;

  Future<PuzzleBatch?> fetch({
    required UserId? userId,
    PuzzleThemeKey angle = PuzzleThemeKey.mix,
  }) async {
    final list = await _db.query(
      _tableName,
      where: '''
      userId = ? AND
      angle = ?
    ''',
      whereArgs: [
        userId?.value ?? _anonUserKey,
        angle.name,
      ],
    );

    final raw = list.firstOrNull?['data'] as String?;

    if (raw != null) {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        throw const FormatException(
          '[PuzzleBatchStorage] cannot fetch puzzles: expected an object',
        );
      }
      return PuzzleBatch.fromJson(json);
    }
    return null;
  }

  Future<void> save({
    required UserId? userId,
    required PuzzleBatch data,
    PuzzleThemeKey angle = PuzzleThemeKey.mix,
  }) async {
    await _db.insert(
      _tableName,
      {
        'userId': userId?.value ?? _anonUserKey,
        'angle': angle.name,
        'data': jsonEncode(data.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete({
    required UserId? userId,
    PuzzleThemeKey angle = PuzzleThemeKey.mix,
  }) async {
    await _db.delete(
      _tableName,
      where: '''
      userId = ? AND
      angle = ?
    ''',
      whereArgs: [
        userId?.value ?? _anonUserKey,
        angle.name,
      ],
    );
  }

  Future<ISet<PuzzleThemeKey>> fetchSavedThemes({
    required UserId? userId,
  }) async {
    final list = await _db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [
        userId?.value ?? _anonUserKey,
      ],
    );

    return list.fold<ISet<PuzzleThemeKey>>(
      ISet<PuzzleThemeKey>(const {}),
      (set, map) {
        final angle = map['angle'] as String?;
        final theme = angle != null ? puzzleThemeNameMap.get(angle) : null;
        return theme != null ? set.add(theme) : set;
      },
    );
  }
}

@Freezed(fromJson: true, toJson: true)
class PuzzleBatch with _$PuzzleBatch {
  const factory PuzzleBatch({
    required IList<PuzzleSolution> solved,
    required IList<Puzzle> unsolved,
  }) = _PuzzleBatch;

  factory PuzzleBatch.fromJson(Map<String, dynamic> json) =>
      _$PuzzleBatchFromJson(json);
}
