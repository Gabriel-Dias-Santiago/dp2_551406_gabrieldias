import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/issues_provider.dart';
import '../app_theme.dart';
import '../widgets/app_navigation.dart';
import '../widgets/common.dart';
import '../widgets/issue_card.dart';
import '../widgets/neighborhood_art.dart';
import 'issue_form_screen.dart';
import 'issue_list_screen.dart';
import 'neighborhoods_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const Padding(
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.holiday_village_outlined),
      ),
      title: const Text('bairro em dia'),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: Text(
            'CITIZENTECH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: const AppNavigation(selectedIndex: 0),
    body: SafeArea(
      child: Consumer<IssuesProvider>(
        builder: (context, provider, _) => RecordsState(
          child: RefreshIndicator(
            onRefresh: provider.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: PageBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 23, 22, 0),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PEQUENAS AÇÕES. GRANDES MUDANÇAS.',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.4,
                              color: Color(0xFFCEE0C6),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Um bairro melhor\ncomeça com você.',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Observe, registre e acompanhe os cuidados com a sua comunidade.',
                            style: TextStyle(
                              color: Color(0xFFDAE7DC),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            key: const ValueKey('home-create'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFDCE9C8),
                              foregroundColor: AppColors.ink,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const IssueFormScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Registrar um problema'),
                          ),
                          const SizedBox(height: 12),
                          const NeighborhoodArt(),
                        ],
                      ),
                    ),
                    const SectionHeading('O bairro em números'),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Metric(
                            width: (constraints.maxWidth - 20) / 3,
                            value: provider.total,
                            label: 'Registros',
                            icon: Icons.assignment_outlined,
                          ),
                          _Metric(
                            width: (constraints.maxWidth - 20) / 3,
                            value: provider.pending,
                            label: 'Pendentes',
                            icon: Icons.schedule,
                            color: AppColors.orange,
                          ),
                          _Metric(
                            width: (constraints.maxWidth - 20) / 3,
                            value: provider.resolved,
                            label: 'Resolvidos',
                            icon: Icons.task_alt,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: const Icon(
                          Icons.near_me_outlined,
                          color: AppColors.green,
                        ),
                        title: const Text(
                          'Onde precisamos agir?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${provider.attention} com atenção prioritária · veja por bairro',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const NeighborhoodsScreen(),
                          ),
                        ),
                      ),
                    ),
                    SectionHeading(
                      'Registros recentes',
                      action: 'Ver todos',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const IssueListScreen(),
                        ),
                      ),
                    ),
                    if (provider.total == 0)
                      EmptyState(
                        title: 'Todo cuidado começa por um olhar',
                        message: 'Registre o primeiro problema do seu bairro.',
                        action: 'Criar registro',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const IssueFormScreen(),
                          ),
                        ),
                      )
                    else
                      ...provider.issues
                          .take(2)
                          .map(
                            (issue) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: IssueCard(issue),
                            ),
                          ),
                    const SectionHeading('Nosso compromisso com os ODS'),
                    const Text(
                      'Cuidar da rua também é cuidar do futuro.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    const _OdsTile(
                      number: '3',
                      title: 'Saúde e bem-estar',
                      text: 'Identificar resíduos e água parada ajuda a priorizar ambientes mais saudáveis.',
                      color: Color(0xFF3F7E44),
                    ),
                    const _OdsTile(
                      number: '11',
                      title: 'Cidades e comunidades sustentáveis',
                      text: 'Acompanhar calçadas, iluminação e espaços públicos acessíveis.',
                      color: Color(0xFFA75C17),
                    ),
                    const _OdsTile(
                      number: '13',
                      title: 'Ação contra a mudança global do clima',
                      text: 'Mapear a necessidade de limpeza de bueiros apoia a preparação para chuvas.',
                      color: Color(0xFF3F6844),
                    ),
                    const SizedBox(height: 12),
                    InfoNote(
                      provider.hasExamples
                          ? 'Os registros iniciais são exemplos fictícios. Seus dados ficam neste dispositivo; não há envio à prefeitura.'
                          : 'Seus registros ficam neste dispositivo. Use-os para organizar demandas; o app não envia solicitações à prefeitura.',
                      icon: Icons.phonelink_lock_outlined,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.green,
  });
  final double width;
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OdsTile extends StatelessWidget {
  const _OdsTile({
    required this.number,
    required this.title,
    required this.text,
    required this.color,
  });
  final String number;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ODS $number · $title',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
