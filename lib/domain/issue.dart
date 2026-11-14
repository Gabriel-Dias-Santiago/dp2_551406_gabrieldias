enum IssueCategory {
  waste('Resíduos', 'Descarte irregular e limpeza de espaços públicos'),
  drainage('Drenagem', 'Bueiros, água parada e pontos de alagamento'),
  lighting('Iluminação', 'Lâmpadas e segurança dos caminhos'),
  accessibility('Acessibilidade', 'Calçadas, rampas e circulação de pessoas');

  const IssueCategory(this.label, this.description);
  final String label;
  final String description;
}

enum IssuePriority {
  low('Baixa'),
  medium('Média'),
  high('Alta');

  const IssuePriority(this.label);
  final String label;
}

enum IssueStatus {
  open('Aberto'),
  inProgress('Em andamento'),
  resolved('Resolvido');

  const IssueStatus(this.label);
  final String label;
}

/// Dados editáveis. Regras compartilhadas pelo formulário e pelo repositório.
class IssueDraft {
  const IssueDraft({
    required this.title,
    required this.description,
    required this.neighborhood,
    required this.address,
    required this.category,
    required this.priority,
    required this.status,
    required this.hasRisk,
  });

  factory IssueDraft.fromIssue(Issue issue) => IssueDraft(
    title: issue.title,
    description: issue.description,
    neighborhood: issue.neighborhood,
    address: issue.address,
    category: issue.category,
    priority: issue.priority,
    status: issue.status,
    hasRisk: issue.hasRisk,
  );

  final String title;
  final String description;
  final String neighborhood;
  final String address;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus status;
  final bool hasRisk;

  void validate() {
    for (final entry in [
      (title, 'Título', 5, 80),
      (description, 'Descrição', 15, 1000),
      (neighborhood, 'Bairro', 2, 60),
      (address, 'Local de referência', 5, 160),
    ]) {
      final error = validateText(entry.$1, entry.$2, entry.$3, entry.$4);
      if (error != null) throw FormatException(error);
    }
  }

  Map<String, Object?> toMap() => {
    'title': title.trim(),
    'description': description.trim(),
    'neighborhood': neighborhood.trim(),
    'address': address.trim(),
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'has_risk': hasRisk ? 1 : 0,
  };
}

String? validateText(String? value, String label, int min, int max) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Informe ${label.toLowerCase()}.';
  if (text.length < min) return '$label: mínimo de $min caracteres.';
  if (text.length > max) return '$label: máximo de $max caracteres.';
  return null;
}

class Issue {
  const Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.neighborhood,
    required this.address,
    required this.category,
    required this.priority,
    required this.status,
    required this.hasRisk,
    required this.createdAt,
    required this.updatedAt,
    this.isDemo = false,
  });

  factory Issue.fromMap(Map<String, Object?> map) => Issue(
    id: map['id'] as int,
    title: map['title'] as String,
    description: map['description'] as String,
    neighborhood: map['neighborhood'] as String,
    address: map['address'] as String,
    category: IssueCategory.values.byName(map['category'] as String),
    priority: IssuePriority.values.byName(map['priority'] as String),
    status: IssueStatus.values.byName(map['status'] as String),
    hasRisk: map['has_risk'] == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    isDemo: map['is_demo'] == 1,
  );

  final int id;
  final String title;
  final String description;
  final String neighborhood;
  final String address;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus status;
  final bool hasRisk;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDemo;

  bool get isPending => status != IssueStatus.resolved;
  bool get needsAttention =>
      isPending && (hasRisk || priority == IssuePriority.high);

  Map<String, Object?> toMap() => {
    'id': id,
    ...IssueDraft.fromIssue(this).toMap(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'is_demo': isDemo ? 1 : 0,
  };
}
