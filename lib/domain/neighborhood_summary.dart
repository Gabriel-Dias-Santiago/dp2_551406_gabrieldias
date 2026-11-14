import 'issue.dart';

class NeighborhoodSummary {
  const NeighborhoodSummary({required this.name, required this.issues});
  final String name;
  final List<Issue> issues;

  int get pending => issues.where((issue) => issue.isPending).length;
  int get attention => issues.where((issue) => issue.needsAttention).length;
  int get resolved => issues.length - pending;

  static List<NeighborhoodSummary> group(List<Issue> issues) {
    final groups = <String, List<Issue>>{};
    for (final issue in issues) {
      final key = issue.neighborhood.trim().toLowerCase();
      groups.putIfAbsent(key, () => []).add(issue);
    }
    return groups.values
        .map(
          (items) => NeighborhoodSummary(
            name: items.first.neighborhood,
            issues: List.unmodifiable(items),
          ),
        )
        .toList()
      ..sort((a, b) {
        final byAttention = b.attention.compareTo(a.attention);
        if (byAttention != 0) return byAttention;
        final byPending = b.pending.compareTo(a.pending);
        return byPending != 0 ? byPending : a.name.compareTo(b.name);
      });
  }
}
