import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/issue.dart';
import '../../state/issues_provider.dart';
import '../app_theme.dart';
import '../widgets/common.dart';
import '../widgets/issue_card.dart';
import 'issue_form_screen.dart';

class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({super.key, required this.issueId});
  final int issueId;

  Future<void> _delete(BuildContext context, Issue issue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir este registro?'),
        content: Text(
          '“${issue.title}” será removido deste dispositivo. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir registro'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<IssuesProvider>();
    final success = await provider.delete(issueId);
    if (!context.mounted) return;
    if (success) {
      showFeedback(context, 'Registro excluído com sucesso.');
      Navigator.pop(context);
    } else {
      showFeedback(
        context,
        provider.actionError ?? 'Aguarde e tente novamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssuesProvider>();
    final issue = provider.byId(issueId);
    return PopScope(
      canPop: !provider.saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalhes do registro')),
        body: SafeArea(
          child: RecordsState(
            child: issue == null
                ? const EmptyState(
                    title: 'Registro não encontrado',
                    message: 'Ele pode ter sido excluído. Volte para consultar os demais registros.',
                  )
                : SingleChildScrollView(
                    child: PageBody(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.pale,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  categoryIcon(issue.category),
                                  color: AppColors.green,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  issue.category.label,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusBadge(issue.status),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            issue.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'REGISTRO #${issue.id.toString().padLeft(3, '0')}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            child: Column(
                              children: [
                                _DetailRow(
                                  icon: Icons.place_outlined,
                                  label: 'Bairro',
                                  value: issue.neighborhood,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                _DetailRow(
                                  icon: Icons.signpost_outlined,
                                  label: 'Local de referência',
                                  value: issue.address,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                _DetailRow(
                                  icon: Icons.flag_outlined,
                                  label: 'Prioridade',
                                  value: issue.priority.label,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                _DetailRow(
                                  icon: Icons.health_and_safety_outlined,
                                  label: 'Risco para as pessoas',
                                  value: issue.hasRisk
                                      ? 'Sim'
                                      : 'Não identificado',
                                ),
                              ],
                            ),
                          ),
                          const SectionHeading('O que está acontecendo'),
                          Text(
                            issue.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Criado em ${formatDateTime(issue.createdAt)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atualizado em ${formatDateTime(issue.updatedAt)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (issue.isDemo) ...[
                            const InfoNote(
                              'Exemplo fictício para explorar o aplicativo. Você pode editar ou excluir este registro.',
                            ),
                            const SizedBox(height: 20),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const ValueKey('edit'),
                              onPressed: provider.saving
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            IssueFormScreen(issueId: issueId),
                                      ),
                                    ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar registro'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const ValueKey('delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .error,
                              ),
                              onPressed: provider.saving
                                  ? null
                                  : () => _delete(context, issue),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(
                                provider.saving
                                    ? 'Excluindo…'
                                    : 'Excluir registro',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.green, size: 22),
    title: Text(
      label,
      style: const TextStyle(color: AppColors.muted, fontSize: 11),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
  );
}
