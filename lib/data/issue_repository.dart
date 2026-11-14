import '../domain/issue.dart';

abstract interface class IssueRepository {
  Future<List<Issue>> findAll();
  Future<Issue> create(IssueDraft draft);
  Future<Issue> update(int id, IssueDraft draft);
  Future<void> delete(int id);
}
