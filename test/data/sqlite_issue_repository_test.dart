import 'dart:io';

import 'package:dp2_551406_gabrieldias/data/sqlite_issue_repository.dart';
import 'package:dp2_551406_gabrieldias/domain/issue.dart';
import 'package:dp2_551406_gabrieldias/state/issues_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fixtures.dart';

void main() {
  late Directory directory;
  late SqliteIssueRepository repository;
  late DateTime now;
  late String databasePath;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bairro_sqlite_test_');
    databasePath = '${directory.path}/test.db';
    now = fixedTime;
    repository = SqliteIssueRepository(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
      withSeed: false,
      clock: () => now,
    );
  });
  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  group('SQLite real em arquivo temporário', () {
    test('Provider executa CRUD com snapshots reais do SQLite', () async {
      final initial = await repository.create(draft());
      final provider = IssuesProvider(repository);
      addTearDown(provider.dispose);
      await provider.load();
      expect(
        await provider.save(draft(title: 'Nova demanda registrada')),
        isTrue,
      );
      expect(provider.total, 2);
      expect(
        await provider.save(
          draft(status: IssueStatus.resolved),
          id: initial.id,
        ),
        isTrue,
      );
      expect(provider.resolved, 1);
      expect(await provider.delete(initial.id), isTrue);
      expect(provider.total, 1);
      await provider.load();
      expect(provider.issues.single.title, 'Nova demanda registrada');
      expect((await repository.findAll()).single.id, provider.issues.single.id);
    });
    test(
      'primeira consulta cria automaticamente banco e tabela vazia',
      () async {
        expect(await repository.findAll(), isEmpty);
        expect(await File(databasePath).exists(), isTrue);
      },
    );

    test('create atribui id e consulta retorna todos os dados', () async {
      final saved = await repository.create(draft());
      final found = (await repository.findAll()).single;
      expect(saved.id, greaterThan(0));
      expect(found.toMap(), saved.toMap());
      expect(found.createdAt, fixedTime);
      expect(found.isDemo, isFalse);
    });

    test(
      'update mantém id e criação, alterando campos e atualização',
      () async {
        final saved = await repository.create(draft());
        now = now.add(const Duration(hours: 2));
        final updated = await repository.update(
          saved.id,
          draft(
            title: 'Bueiro limpo pela comunidade',
            status: IssueStatus.resolved,
            hasRisk: false,
          ),
        );
        expect(updated.id, saved.id);
        expect(updated.createdAt, saved.createdAt);
        expect(updated.updatedAt, now);
        expect(updated.status, IssueStatus.resolved);
        expect(updated.hasRisk, isFalse);
        expect(
          (await repository.findAll()).single.title,
          'Bueiro limpo pela comunidade',
        );
      },
    );

    test('delete remove o registro do banco', () async {
      final saved = await repository.create(draft());
      await repository.delete(saved.id);
      expect(await repository.findAll(), isEmpty);
    });

    test('dados sobrevivem ao fechamento e reabertura da conexão', () async {
      final saved = await repository.create(draft());
      await repository.close();
      repository = SqliteIssueRepository(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      expect((await repository.findAll()).single.toMap(), saved.toMap());
    });

    test('seed insere quatro exemplos somente na criação inicial', () async {
      await repository.close();
      repository = SqliteIssueRepository(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      expect(await repository.findAll(), hasLength(4));
      expect((await repository.findAll()).every((item) => item.isDemo), isTrue);
      await repository.close();
      expect(await repository.findAll(), hasLength(4));
    });

    test('banco esvaziado não recebe seed novamente', () async {
      await repository.close();
      repository = SqliteIssueRepository(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      for (final item in await repository.findAll()) {
        await repository.delete(item.id);
      }
      await repository.close();
      expect(await repository.findAll(), isEmpty);
    });

    test('gravações inválidas são rejeitadas sem alterar o banco', () async {
      final saved = await repository.create(draft());
      await expectLater(
        repository.create(draft(title: '  ')),
        throwsFormatException,
      );
      await expectLater(
        repository.update(saved.id, draft(title: 'Oi')),
        throwsFormatException,
      );
      expect((await repository.findAll()).single.toMap(), saved.toMap());
    });

    test('update e delete de id inexistente retornam erro', () async {
      await expectLater(repository.update(999, draft()), throwsStateError);
      await expectLater(repository.delete(999), throwsStateError);
      expect(await repository.findAll(), isEmpty);
    });

    test(
      'consulta ordena registros mais recentes e desempata por id',
      () async {
        final first = await repository.create(draft());
        final second = await repository.create(
          draft(title: 'Outro bueiro da rua'),
        );
        now = now.add(const Duration(days: 1));
        final third = await repository.create(
          draft(title: 'Calçada precisa de reparo'),
        );
        expect((await repository.findAll()).map((item) => item.id), [
          third.id,
          second.id,
          first.id,
        ]);
      },
    );

    test('aspas e SQL em campos são tratados como texto', () async {
      const title = "D'água; DROP TABLE issues; --";
      await repository.create(draft(title: title));
      expect((await repository.findAll()).single.title, title);
      await repository.create(draft());
      expect(await repository.findAll(), hasLength(2));
    });

    test('abertura concorrente compartilha o mesmo banco e seed', () async {
      await repository.close();
      repository = SqliteIssueRepository(
        factory: databaseFactoryFfi,
        databasePath: databasePath,
      );
      final results = await Future.wait([
        repository.findAll(),
        repository.findAll(),
      ]);
      expect(results[0], hasLength(4));
      expect(results[1], hasLength(4));
    });
  });
}
