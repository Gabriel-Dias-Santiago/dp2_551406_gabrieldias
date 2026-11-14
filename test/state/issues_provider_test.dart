import 'dart:async';

import 'package:dp2_551406_gabrieldias/domain/issue.dart';
import 'package:dp2_551406_gabrieldias/state/issues_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  late FakeIssueRepository repository;
  late IssuesProvider provider;

  setUp(() {
    repository = FakeIssueRepository([issue()]);
    provider = IssuesProvider(repository);
  });
  tearDown(() => provider.dispose());

  group('IssuesProvider', () {
    test('sinaliza loading, notifica e carrega dados', () async {
      repository.readGate = Completer<List<Issue>>();
      var notifications = 0;
      provider.addListener(() => notifications++);
      final loading = provider.load();
      expect(provider.loading, isTrue);
      repository.readGate!.complete([issue()]);
      await loading;
      expect(provider.loading, isFalse);
      expect(provider.total, 1);
      expect(notifications, 2);
    });

    test('falha de leitura é visível e pode ser recuperada', () async {
      repository.failRead = true;
      await provider.load();
      expect(provider.loadError, isNotNull);
      expect(provider.loading, isFalse);
      repository.failRead = false;
      await provider.load();
      expect(provider.loadError, isNull);
      expect(provider.total, 1);
    });

    test('create atualiza lista e indicadores após confirmação', () async {
      await provider.load();
      expect(
        await provider.save(draft(title: 'Nova demanda da comunidade')),
        isTrue,
      );
      expect(provider.total, 2);
      expect(provider.issues.first.title, 'Nova demanda da comunidade');
      expect(provider.pending, 2);
      expect(provider.attention, 2);
    });

    test('edição reflete nos detalhes e remove atenção de resolvido', () async {
      await provider.load();
      expect(
        await provider.save(draft(status: IssueStatus.resolved), id: 1),
        isTrue,
      );
      expect(provider.byId(1)!.status, IssueStatus.resolved);
      expect(provider.pending, 0);
      expect(provider.attention, 0);
      expect(provider.resolved, 1);
      expect(provider.resolutionRate, 1);
    });

    test('exclusão atualiza lista, busca por id e resumo por bairro', () async {
      await provider.load();
      expect(await provider.delete(1), isTrue);
      expect(provider.issues, isEmpty);
      expect(provider.byId(1), isNull);
      expect(provider.neighborhoods, isEmpty);
      expect(provider.resolutionRate, 0);
    });

    test('falha ao criar mantém estado e permite repetir', () async {
      await provider.load();
      repository.failWrite = true;
      expect(await provider.save(draft()), isFalse);
      expect(provider.total, 1);
      expect(provider.actionError, isNotNull);
      expect(provider.saving, isFalse);
      repository.failWrite = false;
      expect(await provider.save(draft()), isTrue);
      expect(provider.actionError, isNull);
    });

    test('falha ao editar preserva os valores anteriores', () async {
      await provider.load();
      repository.failWrite = true;
      expect(
        await provider.save(draft(title: 'Uma alteração que falha'), id: 1),
        isFalse,
      );
      expect(provider.byId(1)!.title, issue().title);
    });

    test('falha ao excluir preserva o registro', () async {
      await provider.load();
      repository.failWrite = true;
      expect(await provider.delete(1), isFalse);
      expect(provider.byId(1), isNotNull);
      expect(provider.actionError, contains('mantido'));
    });

    test('validação do domínio impede escrita inválida', () async {
      await provider.load();
      expect(await provider.save(draft(title: ' ')), isFalse);
      expect(repository.writeCalls, 0);
      expect(provider.actionError, contains('título'));
    });

    test('lista pública não permite mutação fora do Provider', () async {
      await provider.load();
      expect(() => provider.issues.clear(), throwsUnsupportedError);
      expect(provider.total, 1);
    });

    test('bloqueia gravação duplicada durante operação pendente', () async {
      await provider.load();
      repository.writeGate = Completer<void>();
      final first = provider.save(draft());
      expect(provider.saving, isTrue);
      expect(provider.total, 1);
      expect(await provider.save(draft()), isFalse);
      expect(await provider.delete(1), isFalse);
      repository.writeGate!.complete();
      expect(await first, isTrue);
      expect(repository.writeCalls, 1);
    });

    test(
      'bloqueia recarga concorrente para não sobrescrever gravação',
      () async {
        await provider.load();
        repository.writeGate = Completer<void>();
        final saving = provider.save(draft());
        await provider.load();
        expect(repository.readCalls, 1);
        repository.writeGate!.complete();
        await saving;
        expect(provider.total, 2);
      },
    );

    test('bloqueia gravações quando leitura inicial falhou', () async {
      repository.failRead = true;
      await provider.load();
      expect(await provider.save(draft()), isFalse);
      expect(repository.writeCalls, 0);
    });
  });
}
