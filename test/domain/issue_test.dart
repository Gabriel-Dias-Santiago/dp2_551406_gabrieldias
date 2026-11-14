import 'package:dp2_551406_gabrieldias/domain/issue.dart';
import 'package:dp2_551406_gabrieldias/domain/neighborhood_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';

void main() {
  group('Modelo e regras de domínio', () {
    test('serialização preserva todos os campos e as datas UTC', () {
      final original = issue();
      final restored = Issue.fromMap(original.toMap());
      expect(restored.toMap(), original.toMap());
      expect(restored.createdAt.isUtc, isTrue);
      expect(restored.hasRisk, isTrue);
      expect(restored.isDemo, isFalse);
    });

    test('rascunho remove espaços das bordas ao persistir', () {
      final value = draft(
        title: '  Bueiro obstruído  ',
        neighborhood: ' Vila Esperança ',
      );
      expect(value.toMap()['title'], 'Bueiro obstruído');
      expect(value.toMap()['neighborhood'], 'Vila Esperança');
    });

    test('título vazio é rejeitado pela regra compartilhada', () {
      expect(() => draft(title: '   ').validate(), throwsFormatException);
    });

    test('validação rejeita título curto e acima do limite', () {
      expect(() => draft(title: 'Oi').validate(), throwsFormatException);
      expect(() => draft(title: 'a' * 81).validate(), throwsFormatException);
      expect(() => draft(title: 'a' * 80).validate(), returnsNormally);
    });

    test('validação rejeita texto nulo e descrição curta', () {
      expect(validateText(null, 'Descrição', 15, 1000), 'Informe descrição.');
      expect(validateText('curta', 'Descrição', 15, 1000), isNotNull);
      expect(
        validateText(
          'Descrição completa para o registro.',
          'Descrição',
          15,
          1000,
        ),
        isNull,
      );
    });

    test('registro resolvido não permanece na atenção prioritária', () {
      final value = issue(value: draft(status: IssueStatus.resolved));
      expect(value.isPending, isFalse);
      expect(value.needsAttention, isFalse);
    });

    test('risco sinalizado ou prioridade alta geram atenção se pendente', () {
      expect(
        issue(value: draft(priority: IssuePriority.low)).needsAttention,
        isTrue,
      );
      expect(issue(value: draft(hasRisk: false)).needsAttention, isTrue);
      expect(
        issue(value: draft(priority: IssuePriority.low, hasRisk: false))
            .needsAttention,
        isFalse,
      );
    });

    test('agregação reúne bairros com diferença de caixa e espaços', () {
      final groups = NeighborhoodSummary.group([
        issue(),
        issue(
          id: 2,
          value: draft(
            neighborhood: ' vila esperança ',
            status: IssueStatus.resolved,
          ),
        ),
      ]);
      expect(groups, hasLength(1));
      expect(groups.single.pending, 1);
      expect(groups.single.resolved, 1);
      expect(groups.single.attention, 1);
    });

    test('ranking prioriza atenção e depois quantidade de pendências', () {
      final groups = NeighborhoodSummary.group([
        issue(
          value: draft(
            neighborhood: 'Centro',
            priority: IssuePriority.low,
            hasRisk: false,
          ),
        ),
        issue(
          id: 2,
          value: draft(
            neighborhood: 'Vila',
            priority: IssuePriority.high,
            hasRisk: false,
          ),
        ),
        issue(
          id: 3,
          value: draft(
            neighborhood: 'Jardim',
            priority: IssuePriority.low,
            hasRisk: false,
          ),
        ),
        issue(
          id: 4,
          value: draft(
            neighborhood: 'Jardim',
            priority: IssuePriority.low,
            hasRisk: false,
          ),
        ),
      ]);
      expect(groups.map((group) => group.name), ['Vila', 'Jardim', 'Centro']);
    });

    test('agregação vazia e rascunho de edição preservam o domínio', () {
      expect(NeighborhoodSummary.group([]), isEmpty);
      expect(IssueDraft.fromIssue(issue()).toMap(), draft().toMap());
    });
  });
}
