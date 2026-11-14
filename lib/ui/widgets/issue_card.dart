import 'package:material_ui/material_ui.dart';

import '../../domain/issue.dart';
import '../app_theme.dart';
import '../screens/issue_detail_screen.dart';
import 'common.dart';

IconData categoryIcon(IssueCategory category) => switch (category) {
  IssueCategory.waste => Icons.recycling,
  IssueCategory.drainage => Icons.water_drop_outlined,
  IssueCategory.lighting => Icons.lightbulb_outline,
  IssueCategory.accessibility => Icons.accessible_forward,
};

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final IssueStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (status) {
      IssueStatus.open => (const Color(0xFF8E4E16), const Color(0xFFFFF0DC)),
      IssueStatus.inProgress => (
        const Color(0xFF2F5C88),
        const Color(0xFFE9F1FA),
      ),
      IssueStatus.resolved => (AppColors.green, AppColors.pale),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class IssueCard extends StatelessWidget {
  const IssueCard(this.issue, {super.key});
  final Issue issue;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('issue-${issue.id}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => IssueDetailScreen(issueId: issue.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.pale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon(issue.category),
                    size: 21,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    issue.category.label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                StatusBadge(issue.status),
              ],
            ),
            const SizedBox(height: 13),
            Text(issue.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    issue.neighborhood,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                  color: AppColors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'Prioridade ${issue.priority.label.toLowerCase()}',
                  style: TextStyle(
                    color: issue.priority == IssuePriority.high
                        ? AppColors.orange
                        : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatDate(issue.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                if (issue.isDemo)
                  const Text(
                    'Exemplo fictício',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
