import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/issues_provider.dart';
import '../app_theme.dart';
import '../widgets/app_navigation.dart';
import '../widgets/common.dart';
import 'issue_form_screen.dart';
import 'issue_list_screen.dart';

class NeighborhoodsScreen extends StatefulWidget {
  const NeighborhoodsScreen({super.key});

  @override
  State<NeighborhoodsScreen> createState() => _NeighborhoodsScreenState();
}

class _NeighborhoodsScreenState extends State<NeighborhoodsScreen> {
  bool _attentionOnly = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssuesProvider>();
    final neighborhoods = provider.neighborhoods
        .where((group) => !_attentionOnly || group.attention > 0)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Prioridades por bairro')),
      bottomNavigationBar: const AppNavigation(selectedIndex: 2),
      body: SafeArea(
        child: RecordsState(
          child: PageBody(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Um olhar para o território.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Descubra onde concentrar os próximos cuidados da comunidade.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.eco_outlined,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Melhorias acompanhadas',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${(provider.resolutionRate * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: provider.resolutionRate,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          backgroundColor: AppColors.pale,
                          semanticsLabel: 'Proporção de registros resolvidos',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${provider.resolved} de ${provider.total} registros resolvidos · ${provider.neighborhoods.length} bairro(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  key: const ValueKey('attention-filter'),
                  contentPadding: EdgeInsets.zero,
                  value: _attentionOnly,
                  onChanged: (value) => setState(() => _attentionOnly = value),
                  title: const Text(
                    'Somente bairros com atenção',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Pendentes com risco ou prioridade alta.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: neighborhoods.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyState(
                                title: provider.total == 0
                                    ? 'Vamos conhecer seu bairro?'
                                    : 'Nenhum bairro com atenção prioritária',
                                message: provider.total == 0
                                    ? 'Crie um registro para começar a acompanhar os cuidados por região.'
                                    : 'Desative o filtro para ver todos os bairros cadastrados.',
                                action: provider.total == 0
                                    ? 'Criar registro'
                                    : 'Ver todos os bairros',
                                onAction: () {
                                  if (provider.total == 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const IssueFormScreen(),
                                      ),
                                    );
                                  } else {
                                    setState(() => _attentionOnly = false);
                                  }
                                },
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: neighborhoods.length + 1,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == neighborhoods.length) {
                                return const InfoNote(
                                  'A ordem considera primeiro os registros que precisam de atenção, depois os pendentes. Acompanhe mudanças atualizando a situação dos registros.',
                                );
                              }
                              final group = neighborhoods[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: ValueKey('neighborhood-${group.name}'),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => IssueListScreen(
                                        neighborhood: group.name,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              (index + 1).toString().padLeft(
                                                2,
                                                '0',
                                              ),
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                group.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 19,
                                              color: AppColors.green,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            Text(
                                              '${group.pending} pendente(s)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                            Text(
                                              '${group.attention} com atenção',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.orange,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${group.resolved} resolvido(s)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
