import 'package:flutter/foundation.dart';

import '../data/issue_repository.dart';
import '../domain/issue.dart';
import '../domain/neighborhood_summary.dart';

class IssuesProvider extends ChangeNotifier {
  IssuesProvider(this._repository);
  final IssueRepository _repository;
  List<Issue> _issues = [];
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  String? _loadError;
  String? _actionError;

  List<Issue> get issues => List.unmodifiable(_issues);
  bool get loading => _loading;
  bool get saving => _saving;
  String? get loadError => _loadError;
  String? get actionError => _actionError;
  int get total => _issues.length;
  int get pending => _issues.where((issue) => issue.isPending).length;
  int get attention => _issues.where((issue) => issue.needsAttention).length;
  int get resolved => total - pending;
  double get resolutionRate => total == 0 ? 0 : resolved / total;
  bool get hasExamples => _issues.any((issue) => issue.isDemo);
  List<NeighborhoodSummary> get neighborhoods =>
      NeighborhoodSummary.group(_issues);

  Issue? byId(int id) {
    for (final issue in _issues) {
      if (issue.id == id) return issue;
    }
    return null;
  }

  Future<void> load() async {
    if (_loading || _saving) return;
    _loading = true;
    _loadError = null;
    _notify();
    try {
      // O repositório pode retornar uma lista fixa/imutável. O estado possui sua
      // própria cópia mutável, sem alterar a coleção fornecida pela camada de dados.
      _issues = List.of(await _repository.findAll());
    } catch (_) {
      _loadError = 'Não foi possível carregar seus registros. Tente novamente.';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<bool> save(IssueDraft draft, {int? id}) async {
    if (_saving || _loading || _loadError != null) return false;
    _saving = true;
    _actionError = null;
    _notify();
    try {
      draft.validate();
      final saved = id == null
          ? await _repository.create(draft)
          : await _repository.update(id, draft);
      // Atualiza a interface apenas depois de a persistência confirmar.
      if (id == null) {
        _issues.insert(0, saved);
      } else {
        final index = _issues.indexWhere((issue) => issue.id == id);
        if (index >= 0) _issues[index] = saved;
      }
      return true;
    } on FormatException catch (error) {
      _actionError = error.message;
      return false;
    } catch (_) {
      _actionError = 'Não foi possível salvar. Seus dados foram mantidos; tente novamente.';
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  Future<bool> delete(int id) async {
    if (_saving || _loading || _loadError != null) return false;
    _saving = true;
    _actionError = null;
    _notify();
    try {
      await _repository.delete(id);
      _issues.removeWhere((issue) => issue.id == id);
      return true;
    } catch (_) {
      _actionError =
          'Não foi possível excluir. O registro foi mantido; tente novamente.';
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
