import 'dart:async';

import 'package:dp2_551406_gabrieldias/app.dart';
import 'package:dp2_551406_gabrieldias/domain/issue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fixtures.dart';

Future<void> prepare(
  WidgetTester tester,
  FakeIssueRepository repository, {
  double width = 390,
  double height = 844,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(BairroEmDiaApp(repository: repository));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // O relógio do teste só avança explicitamente; aguarda o feedback temporário.
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'navegação e CRUD completos com validação, edição e confirmação',
    (tester) async {
      final repository = FakeIssueRepository();
      await prepare(tester, repository);
      await tapVisible(tester, find.byKey(const ValueKey('home-create')));
      await tapVisible(tester, find.byKey(const ValueKey('save')));
      expect(repository.items, isEmpty);
      expect(find.text('Informe título.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('title')),
        'Calçada quebrada na esquina',
      );
      await tester.enterText(
        find.byKey(const ValueKey('neighborhood')),
        'Vila Nova',
      );
      await tester.enterText(
        find.byKey(const ValueKey('address')),
        'Rua das Flores, 25',
      );
      await tester.enterText(
        find.byKey(const ValueKey('description')),
        'A calçada está quebrada e dificulta a passagem dos moradores.',
      );
      await tapVisible(tester, find.byKey(const ValueKey('save')));
      expect(repository.items, hasLength(1));
      expect(find.text('Registro criado com sucesso!'), findsOneWidget);

      await tapVisible(tester, find.text('Ver todos'));
      await tapVisible(
        tester,
        find.byKey(ValueKey('issue-${repository.items.single.id}')),
      );
      expect(find.text('Rua das Flores, 25'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('edit')));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('title')))
            .controller!
            .text,
        'Calçada quebrada na esquina',
      );
      await tester.enterText(
        find.byKey(const ValueKey('title')),
        'Calçada reparada na esquina',
      );
      await tapVisible(tester, find.byKey(const ValueKey('save')));
      expect(find.text('Calçada reparada na esquina'), findsOneWidget);
      expect(repository.items.single.title, 'Calçada reparada na esquina');

      await tapVisible(tester, find.byKey(const ValueKey('delete')));
      expect(find.text('Excluir este registro?'), findsOneWidget);
      await tapVisible(tester, find.text('Cancelar'));
      expect(repository.items, hasLength(1));
      await tapVisible(tester, find.byKey(const ValueKey('delete')));
      await tapVisible(tester, find.byKey(const ValueKey('confirm-delete')));
      expect(repository.items, isEmpty);
      expect(find.text('Seu bairro começa aqui'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lista pesquisa, filtra situação e apresenta ausência de resultados',
    (tester) async {
      final repository = FakeIssueRepository([
        issue(),
        issue(
          id: 2,
          value: draft(
            title: 'Calçada reparada na avenida',
            status: IssueStatus.resolved,
          ),
        ),
      ]);
      await prepare(tester, repository);
      await tapVisible(tester, find.text('Ver todos'));
      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Resolvido'));
      expect(find.text('Calçada reparada na avenida'), findsOneWidget);
      expect(find.text('Bueiro obstruído na praça'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('search')),
        'inexistente',
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhum registro encontrado'), findsOneWidget);
      await tapVisible(tester, find.text('Limpar filtros'));
      expect(find.text('2 registro(s)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quinta tela filtra bairros e abre a lista com argumento', (
    tester,
  ) async {
    await prepare(
      tester,
      FakeIssueRepository([
        issue(),
        issue(
          id: 2,
          value: draft(neighborhood: 'Centro', status: IssueStatus.resolved),
        ),
      ]),
    );
    await tapVisible(tester, find.text('Bairros'));
    expect(find.text('Prioridades por bairro'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('attention-filter')));
    expect(find.text('Centro'), findsNothing);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('neighborhood-Vila Esperança')),
    );
    expect(find.text('Vila Esperança'), findsWidgets);
    expect(find.text('1 registro(s)'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('search')), 'inexistente');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Limpar filtros'));
    expect(find.text('2 registro(s)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leitura apresenta loading e erro com recuperação', (
    tester,
  ) async {
    final repository = FakeIssueRepository()
      ..readGate = Completer<List<Issue>>();
    await tester.pumpWidget(BairroEmDiaApp(repository: repository));
    await tester.pump();
    expect(find.text('Carregando registros…'), findsOneWidget);
    repository.readGate!.completeError(StateError('Falha simulada'));
    await tester.pumpAndSettle();
    expect(find.text('Vamos tentar de novo?'), findsOneWidget);
    repository.readGate = null;
    await tapVisible(tester, find.text('Tentar novamente'));
    expect(find.text('bairro em dia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falha de exclusão mantém detalhes e mostra feedback', (
    tester,
  ) async {
    final repository = FakeIssueRepository([issue()]);
    await prepare(tester, repository);
    await tapVisible(tester, find.byKey(const ValueKey('issue-1')));
    repository.failWrite = true;
    await tapVisible(tester, find.byKey(const ValueKey('delete')));
    await tapVisible(tester, find.byKey(const ValueKey('confirm-delete')));
    expect(find.text('Detalhes do registro'), findsOneWidget);
    expect(find.textContaining('O registro foi mantido'), findsOneWidget);
    expect(repository.items, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout em largura de 320 e texto ampliado permite navegação', (
    tester,
  ) async {
    await prepare(
      tester,
      FakeIssueRepository([issue()]),
      width: 320,
      height: 740,
    );
    final context = tester.element(find.byType(Scaffold).first);
    final mediaQuery = MediaQuery.of(context);
    await tester.pumpWidget(
      MediaQuery(
        data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.3)),
        child: BairroEmDiaApp(repository: FakeIssueRepository([issue()])),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.byKey(const ValueKey('home-create')));
    expect(find.text('Novo registro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
