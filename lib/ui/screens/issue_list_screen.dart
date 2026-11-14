import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/issue.dart';
import '../../state/issues_provider.dart';
import '../app_theme.dart';
import '../widgets/app_navigation.dart';
import '../widgets/common.dart';
import '../widgets/issue_card.dart';
import 'issue_form_screen.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key, this.neighborhood});
  final String? neighborhood;

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  final _search = TextEditingController();
  IssueStatus? _status;
  String _query = '';
  String? _neighborhood;

  @override
  void initState() {
    super.initState();
    _neighborhood = widget.neighborhood;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssuesProvider>();
    final issues = provider.issues.where((issue) {
      final neighborhoodMatches =
          _neighborhood == null ||
          issue.neighborhood.trim().toLowerCase() ==
              _neighborhood!.trim().toLowerCase();
      final text =
          '${issue.title} ${issue.neighborhood} ${issue.address} ${issue.category.label}'
              .toLowerCase();
      return neighborhoodMatches &&
          (_status == null || issue.status == _status) &&
          text.contains(_query.trim().toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(_neighborhood ?? 'Registros do bairro')),
      bottomNavigationBar: const AppNavigation(selectedIndex: 1),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('list-create'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const IssueFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: SafeArea(
        child: RecordsState(
          child: PageBody(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cada registro é um passo para melhorar a rua.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('search'),
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    labelText: 'Buscar registros',
                    hintText: 'Título, bairro, local ou categoria',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _status == null,
                        onSelected: (_) => setState(() => _status = null),
                      ),
                      for (final status in IssueStatus.values)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(status.label),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    '${issues.length} registro(s)',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: issues.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyState(
                                title: provider.total == 0
                                    ? 'Seu bairro começa aqui'
                                    : 'Nenhum registro encontrado',
                                message: provider.total == 0
                                    ? 'Conte o que precisa de cuidado. Seu primeiro registro pode fazer a diferença.'
                                    : 'Tente outra busca ou altere os filtros.',
                                action: provider.total == 0
                                    ? 'Criar primeiro registro'
                                    : 'Limpar filtros',
                                onAction: () {
                                  if (provider.total == 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const IssueFormScreen(),
                                      ),
                                    );
                                  } else {
                                    _search.clear();
                                    setState(() {
                                      _status = null;
                                      _query = '';
                                      _neighborhood = null;
                                    });
                                  }
                                },
                              ),
                            ],
                          )
                        : ListView.separated(
                            key: const ValueKey('issues-list'),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: issues.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => IssueCard(issues[index]),
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
