import '../domain/issue.dart';

/// Exemplos fictícios, identificados como tal na interface.
List<Map<String, Object?>> seedData(DateTime now) {
  final drafts = [
    const IssueDraft(
      title: 'Bueiro obstruído na praça',
      description: 'Folhas e resíduos bloqueiam a passagem da água. O trecho acumula água em dias de chuva e precisa de limpeza preventiva.',
      neighborhood: 'Vila Esperança',
      address: 'Praça das Flores, em frente ao número 120',
      category: IssueCategory.drainage,
      priority: IssuePriority.high,
      status: IssueStatus.open,
      hasRisk: true,
    ),
    const IssueDraft(
      title: 'Descarte irregular de resíduos',
      description: 'Sacos de lixo e entulho estão sobre a calçada, dificultando a passagem e atraindo insetos para o local.',
      neighborhood: 'Jardim União',
      address: 'Rua das Acácias, próximo ao ponto de ônibus',
      category: IssueCategory.waste,
      priority: IssuePriority.medium,
      status: IssueStatus.inProgress,
      hasRisk: false,
    ),
    const IssueDraft(
      title: 'Rampa de acesso danificada',
      description: 'A rampa da esquina está quebrada. Pessoas com mobilidade reduzida precisam desviar pela rua para atravessar.',
      neighborhood: 'Vila Esperança',
      address: 'Rua do Sol com Avenida Central',
      category: IssueCategory.accessibility,
      priority: IssuePriority.high,
      status: IssueStatus.open,
      hasRisk: true,
    ),
    const IssueDraft(
      title: 'Iluminação da passagem recuperada',
      description: 'A lâmpada da passagem de pedestres voltou a funcionar. Registro de exemplo para acompanhar uma melhoria concluída.',
      neighborhood: 'Centro',
      address: 'Passagem dos Ipês, ao lado da biblioteca',
      category: IssueCategory.lighting,
      priority: IssuePriority.low,
      status: IssueStatus.resolved,
      hasRisk: false,
    ),
  ];
  return [
    for (var i = 0; i < drafts.length; i++)
      {
        ...drafts[i].toMap(),
        'created_at': now
            .subtract(Duration(days: i + 1))
            .toUtc()
            .toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
        'is_demo': 1,
      },
  ];
}
