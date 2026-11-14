import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/issue.dart';
import '../../state/issues_provider.dart';
import '../app_theme.dart';
import '../widgets/common.dart';

class IssueFormScreen extends StatefulWidget {
  const IssueFormScreen({super.key, this.issueId});
  final int? issueId;

  @override
  State<IssueFormScreen> createState() => _IssueFormScreenState();
}

class _IssueFormScreenState extends State<IssueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _neighborhood = TextEditingController();
  final _address = TextEditingController();
  IssueCategory _category = IssueCategory.waste;
  IssuePriority _priority = IssuePriority.medium;
  IssueStatus _status = IssueStatus.open;
  bool _hasRisk = false;
  bool _submitted = false;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    final id = widget.issueId;
    if (id == null) return;
    final issue = context.read<IssuesProvider>().byId(id);
    if (issue == null) {
      _missing = true;
      return;
    }
    _title.text = issue.title;
    _description.text = issue.description;
    _neighborhood.text = issue.neighborhood;
    _address.text = issue.address;
    _category = issue.category;
    _priority = issue.priority;
    _status = issue.status;
    _hasRisk = issue.hasRisk;
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final controller in [_title, _description, _neighborhood, _address]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      _scroll.jumpTo(0);
      return;
    }
    FocusScope.of(context).unfocus();
    final provider = context.read<IssuesProvider>();
    final success = await provider.save(
      IssueDraft(
        title: _title.text,
        description: _description.text,
        neighborhood: _neighborhood.text,
        address: _address.text,
        category: _category,
        priority: _priority,
        status: _status,
        hasRisk: _hasRisk,
      ),
      id: widget.issueId,
    );
    if (!mounted) return;
    if (success) {
      showFeedback(
        context,
        widget.issueId == null
            ? 'Registro criado com sucesso!'
            : 'Registro atualizado com sucesso!',
      );
      Navigator.pop(context);
    } else {
      showFeedback(
        context,
        provider.actionError ?? 'Aguarde o carregamento e tente novamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IssuesProvider>();
    return PopScope(
      canPop: !provider.saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.issueId == null ? 'Novo registro' : 'Editar registro',
          ),
        ),
        body: SafeArea(
          child: _missing
              ? const EmptyState(
                  title: 'Registro indisponível',
                  message: 'Volte à lista para selecionar outro registro.',
                )
              : RecordsState(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: PageBody(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _submitted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.issueId == null
                                  ? 'O que precisa de cuidado?'
                                  : 'Atualize o acompanhamento',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Descreva o problema e ajude a organizar as próximas ações. Todos os campos são obrigatórios.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 24),
                            _field(
                              controller: _title,
                              fieldKey: 'title',
                              label: 'Título',
                              min: 5,
                              max: 80,
                              hint: 'Ex.: Bueiro obstruído na praça',
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<IssueCategory>(
                              key: const ValueKey('category'),
                              isExpanded: true,
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                              ),
                              items: IssueCategory.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: provider.saving
                                  ? null
                                  : (value) =>
                                        setState(() => _category = value!),
                              validator: (value) => value == null
                                  ? 'Selecione a categoria.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              controller: _neighborhood,
                              fieldKey: 'neighborhood',
                              label: 'Bairro',
                              min: 2,
                              max: 60,
                              hint: 'Ex.: Vila Esperança',
                            ),
                            const SizedBox(height: 16),
                            _field(
                              controller: _address,
                              fieldKey: 'address',
                              label: 'Local de referência',
                              min: 5,
                              max: 160,
                              hint: 'Rua, número ou ponto de referência',
                            ),
                            const SizedBox(height: 16),
                            _field(
                              controller: _description,
                              fieldKey: 'description',
                              label: 'Descrição',
                              min: 15,
                              max: 1000,
                              hint: 'O que aconteceu? Como afeta as pessoas?',
                              lines: 4,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<IssuePriority>(
                              key: const ValueKey('priority'),
                              isExpanded: true,
                              initialValue: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Prioridade',
                              ),
                              items: IssuePriority.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: provider.saving
                                  ? null
                                  : (value) =>
                                        setState(() => _priority = value!),
                              validator: (value) => value == null
                                  ? 'Selecione a prioridade.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<IssueStatus>(
                              key: const ValueKey('status'),
                              isExpanded: true,
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Situação',
                              ),
                              items: IssueStatus.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: provider.saving
                                  ? null
                                  : (value) => setState(() => _status = value!),
                              validator: (value) => value == null
                                  ? 'Selecione a situação.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              key: const ValueKey('risk'),
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Há risco para as pessoas?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: const Text(
                                'Ajuda a destacar o registro nas prioridades.',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _hasRisk,
                              onChanged: provider.saving
                                  ? null
                                  : (value) => setState(() => _hasRisk = value),
                            ),
                            const SizedBox(height: 12),
                            const InfoNote(
                              'Use apenas informações do espaço público. Evite nomes, telefones e outros dados pessoais.',
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: const ValueKey('save'),
                                onPressed: provider.saving ? null : _save,
                                icon: provider.saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(
                                  provider.saving
                                      ? 'Salvando…'
                                      : widget.issueId == null
                                      ? 'Salvar registro'
                                      : 'Salvar alterações',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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

  Widget _field({
    required TextEditingController controller,
    required String fieldKey,
    required String label,
    required int min,
    required int max,
    required String hint,
    int lines = 1,
  }) => TextFormField(
    key: ValueKey(fieldKey),
    controller: controller,
    enabled: !context.read<IssuesProvider>().saving,
    decoration: InputDecoration(labelText: label, hintText: hint),
    minLines: lines,
    maxLines: lines == 1 ? 1 : 6,
    maxLength: max,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: lines == 1
        ? TextInputAction.next
        : TextInputAction.newline,
    validator: (value) => validateText(value, label, min, max),
  );
}
