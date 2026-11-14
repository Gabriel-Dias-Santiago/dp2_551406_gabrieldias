import 'dart:async';

import 'package:dp2_551406_gabrieldias/data/issue_repository.dart';
import 'package:dp2_551406_gabrieldias/domain/issue.dart';

final fixedTime = DateTime.utc(2026, 11, 13, 15);

IssueDraft draft({
  String title = 'Bueiro obstruído na praça',
  String neighborhood = 'Vila Esperança',
  IssueStatus status = IssueStatus.open,
  IssuePriority priority = IssuePriority.high,
  bool hasRisk = true,
}) => IssueDraft(
  title: title,
  description: 'Folhas e resíduos impedem a passagem da água na praça.',
  neighborhood: neighborhood,
  address: 'Praça das Flores, 120',
  category: IssueCategory.drainage,
  priority: priority,
  status: status,
  hasRisk: hasRisk,
);

Issue issue({int id = 1, IssueDraft? value}) => Issue.fromMap({
  ...(value ?? draft()).toMap(),
  'id': id,
  'created_at': fixedTime.toIso8601String(),
  'updated_at': fixedTime.toIso8601String(),
  'is_demo': 0,
});

/// Fake somente para isolar o Provider e os widgets das operações de disco.
class FakeIssueRepository implements IssueRepository {
  FakeIssueRepository([List<Issue>? initial]) : items = [...?initial];
  List<Issue> items;
  bool failRead = false;
  bool failWrite = false;
  Completer<List<Issue>>? readGate;
  Completer<void>? writeGate;
  int readCalls = 0;
  int writeCalls = 0;
  int _nextId = 100;

  @override
  Future<List<Issue>> findAll() async {
    readCalls++;
    if (failRead) throw StateError('Falha simulada de leitura');
    return readGate == null ? List.unmodifiable(items) : await readGate!.future;
  }

  Future<void> _beforeWrite() async {
    writeCalls++;
    if (writeGate != null) await writeGate!.future;
    if (failWrite) throw StateError('Falha simulada de gravação');
  }

  @override
  Future<Issue> create(IssueDraft draft) async {
    await _beforeWrite();
    final saved = issue(id: _nextId++, value: draft);
    items.insert(0, saved);
    return saved;
  }

  @override
  Future<Issue> update(int id, IssueDraft draft) async {
    await _beforeWrite();
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Registro ausente');
    return items[index] = issue(id: id, value: draft);
  }

  @override
  Future<void> delete(int id) async {
    await _beforeWrite();
    if (!items.any((item) => item.id == id)) {
      throw StateError('Registro ausente');
    }
    items.removeWhere((item) => item.id == id);
  }
}
