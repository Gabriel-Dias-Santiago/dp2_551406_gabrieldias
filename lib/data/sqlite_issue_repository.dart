import 'package:path/path.dart' as path;
import 'package:sqflite_common/sqlite_api.dart';

import '../domain/issue.dart';
import 'database_connection.dart';
import 'issue_repository.dart';
import 'seed_data.dart';

class SqliteIssueRepository implements IssueRepository {
  SqliteIssueRepository({
    this.factory,
    this.databasePath,
    this.withSeed = true,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DatabaseFactory? factory;
  final String? databasePath;
  final bool withSeed;
  final DateTime Function() _clock;
  Future<Database>? _opening;

  Future<Database> get _database async {
    // Compartilha a abertura concorrente e permite repetir após uma falha.
    try {
      return await (_opening ??= _open());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final connectionFactory = factory ?? platformDatabaseFactory();
    final location =
        databasePath ??
        path.join(
          await connectionFactory.getDatabasesPath(),
          'bairro_em_dia.db',
        );
    return connectionFactory.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE issues (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL CHECK(length(trim(title)) BETWEEN 5 AND 80),
              description TEXT NOT NULL CHECK(length(trim(description)) BETWEEN 15 AND 1000),
              neighborhood TEXT NOT NULL CHECK(length(trim(neighborhood)) BETWEEN 2 AND 60),
              address TEXT NOT NULL CHECK(length(trim(address)) BETWEEN 5 AND 160),
              category TEXT NOT NULL CHECK(category IN ('waste','drainage','lighting','accessibility')),
              priority TEXT NOT NULL CHECK(priority IN ('low','medium','high')),
              status TEXT NOT NULL CHECK(status IN ('open','inProgress','resolved')),
              has_risk INTEGER NOT NULL CHECK(has_risk IN (0,1)),
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              is_demo INTEGER NOT NULL DEFAULT 0 CHECK(is_demo IN (0,1))
            )
          ''');
          if (withSeed) {
            final batch = db.batch();
            for (final row in seedData(_clock())) {
              batch.insert('issues', row);
            }
            await batch.commit(noResult: true);
          }
        },
      ),
    );
  }

  @override
  Future<List<Issue>> findAll() async {
    final db = await _database;
    final rows = await db.query('issues', orderBy: 'created_at DESC, id DESC');
    return rows.map(Issue.fromMap).toList(growable: false);
  }

  @override
  Future<Issue> create(IssueDraft draft) async {
    draft.validate();
    final db = await _database;
    final timestamp = _clock().toUtc().toIso8601String();
    final row = {
      ...draft.toMap(),
      'created_at': timestamp,
      'updated_at': timestamp,
      'is_demo': 0,
    };
    final id = await db.insert('issues', row);
    return Issue.fromMap({...row, 'id': id});
  }

  @override
  Future<Issue> update(int id, IssueDraft draft) async {
    draft.validate();
    final db = await _database;
    return db.transaction((transaction) async {
      final changes = {
        ...draft.toMap(),
        'updated_at': _clock().toUtc().toIso8601String(),
      };
      final affected = await transaction.update(
        'issues',
        changes,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (affected != 1) throw StateError('Registro não encontrado.');
      final rows = await transaction.query(
        'issues',
        where: 'id = ?',
        whereArgs: [id],
      );
      return Issue.fromMap(rows.single);
    });
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database;
    final affected = await db.delete(
      'issues',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (affected != 1) throw StateError('Registro não encontrado.');
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await (await opening).close();
    _opening = null;
  }
}
