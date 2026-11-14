# Validação do Bairro em Dia

Data: **13/11/2026**. Integrante: **Gabriel Dias Santiago — RM 551406**.

## Ambiente de teste

- Ubuntu 24.04.5 LTS, Linux x64.
- Flutter **3.50.0 stable**, Dart **3.14.0**.
- Chrome **157.0.8103.50**.
- Ferramentas Linux (clang, cmake, ninja e GTK) disponíveis.
- **Android SDK ausente**; Xcode/iOS não disponíveis neste Linux.

## Comandos e resultados

| Comando | Resultado observado |
| --- | --- |
| `flutter pub get` | Dependências públicas instaladas; lockfile gerado e mantido no projeto. |
| `dart format lib test` | Arquivos Dart formatados. |
| `flutter analyze` | **No issues found!** |
| `flutter test --reporter expanded` | **42 testes aprovados; nenhuma falha.** |
| `flutter build web --no-web-resources-cdn` | Compilação web concluída. |
| `flutter run -d web-server --release --web-hostname=127.0.0.1 --web-port=7357 --no-web-resources-cdn` | Compilou e serviu o app em execução; utilizado para a galeria e verificação no Chrome. |
| `flutter build linux` | Binário Linux compilado com sucesso. |
| `flutter run -d linux --release` | App nativo iniciou com Impeller; o banco criado pelo aplicativo continha 4 registros, todos identificados como exemplos. |
| Build/execução Android e iOS | **Não executados:** faltam Android SDK/emulador e ambiente macOS/Xcode. |
| Cópia limpa + `flutter pub get` + `flutter run -d linux --release` | **Aprovado:** sem build, banco, `.dart_tool` ou configurações locais; app compilou, abriu e criou automaticamente 4 exemplos. |
| Clone do repositório público + `flutter pub get` + `flutter run -d linux --release` | **Aprovado:** instalação, compilação e inicialização a partir do GitHub; banco criado automaticamente com os 4 exemplos. |

## Composição dos testes

- `test/domain/issue_test.dart`: **10** testes de modelos, serialização, validação e regras de priorização.
- `test/state/issues_provider_test.dart`: **13** testes de estado, notificações, erros e concorrência.
- `test/data/sqlite_issue_repository_test.dart`: **12** testes do repositório com SQLite real em arquivos temporários e **1** teste de integração Provider/SQLite.
- `test/ui/app_test.dart`: **6** testes de interface, incluindo CRUD, cancelamento/confirmação de exclusão, edição preenchida, validação, filtros, erro e recuperação, quinta tela e largura de 320 px com texto ampliado.

Total: **35 testes das camadas de domínio/dados/estado, 1 de integração entre Provider e SQLite e 6 de interface**. Todos são executados por `flutter test`; não é necessário emulador para essa suíte.

O teste de integração verifica o CRUD através do Provider usando SQLite real. A coleção retornada pelo repositório é copiada para uma lista mutável no Provider, permitindo inserir e excluir registros sem alterar o snapshot da camada de dados.

## Verificação no Chrome e screenshots

O roteiro opcional `tool/browser_smoke.cjs` executa o aplicativo com SQLite/WASM e um perfil independente do Chrome. Ele registra a criação, leitura, edição, confirmação/cancelamento e exclusão; recarrega a página para verificar persistência; verifica o painel reativo, filtros por bairro, lista vazia e ausência de novo seed após exclusão de todos os dados.

O roteiro bloqueia recursos de domínios externos durante a verificação. As capturas estão em `docs/screenshots/`; a viewport tem largura de 390 px e escala de imagem 2. Formulário e detalhes usam uma viewport mais alta para incluir o conteúdo. A galeria representa a versão web real do aplicativo Flutter, **não uma captura de emulador Android ou iPhone**.

Resultado real: **todos os passos aprovados, nenhum erro JavaScript e nenhuma requisição externa**. A edição alterou o painel para 40% de resolvidos (2 de 5 registros); a exclusão foi confirmada também após recarregar a aplicação. O resultado está em [`browser-result.json`](browser-result.json), e as **10 capturas reais** estão na galeria do README.

Foram acrescentados **3 prints desktop complementares** de Home, Listagem e Prioridades por Bairro, em viewport de 1440 × 1000 px. A [galeria completa](SCREENSHOTS.md) reúne as **13 capturas** e relaciona cada print obrigatório à exigência da prova. Os três prints adicionais foram capturados no Chrome, usando o aplicativo real e um contexto descartável com os quatro exemplos iniciais.

### Reproduzir a galeria (opcional)

Isso não faz parte da instalação ou execução normal do app e não é necessário para `flutter pub get`, `flutter run` ou `flutter test`.

1. Inicie o app com os recursos web locais:

```bash
flutter run -d web-server --release --web-hostname=127.0.0.1 --web-port=7357 --no-web-resources-cdn
```

2. Em outro terminal, com Node.js e Chrome instalados, instale o Playwright em um diretório temporário e execute:

```bash
npm --prefix /tmp/bairro-browser install playwright@1.48.2
NODE_PATH=/tmp/bairro-browser/node_modules node tool/browser_smoke.cjs
```

É possível informar `CHROME_EXECUTABLE` com o caminho do Chrome e `APP_URL` para outro endereço do app. O script inicia seu próprio contexto descartável e exclui somente os registros desse contexto. Não modifica o banco do aplicativo nativo.

## Conferência Zero-Config

- Uma única opção de persistência: **SQLite local**.
- Tabela e dados de exemplo criados automaticamente em `onCreate`.
- Formulário de cadastro disponível sem contas ou configuração.
- Nenhum backend, chave privada, `.env` ou processo de API necessário.
- Arquivos SQLite web e fontes já incluídos no repositório.
- Biblioteca SQLite para desktop obtida automaticamente pelas dependências e incorporada ao build; não é preciso instalar manualmente um servidor ou serviço SQLite.
- Reabertura da conexão e reinicialização da aplicação verificadas nos testes e no roteiro web.
- Instalação e execução foram verificadas também em uma **cópia limpa do código**, sem banco e arquivos gerados. O banco criado pela primeira execução continha os 4 exemplos esperados. A instalação e a inicialização também foram verificadas a partir de um clone do repositório público. A execução mobile ainda precisa ser conferida em dispositivo ou emulador.

## Limites da validação

A análise estática, os testes automatizados e a execução web/Linux estão verificados. O ambiente utilizado não possui Android SDK nem Xcode; a execução Android/iOS permanece como verificação adicional em dispositivo ou emulador.

## Arquivo para envio

O item 4.2 do enunciado solicita um arquivo contendo o link do repositório acessível ao professor. O arquivo preparado é [link_repositorio.txt](../entrega/link_repositorio.txt), contendo somente a URL do projeto.

Repositório público: https://github.com/Gabriel-Dias-Santiago/dp2_551406_gabrieldias

O README, os 13 prints e os arquivos SQLite web tiveram o acesso público conferido e o conteúdo comparado com os arquivos locais.

O envio deve ser feito na área de trabalhos da disciplina no Portal do Aluno FIAP até **19/11/2026**. A publicação do repositório não substitui a submissão desse arquivo no portal.
