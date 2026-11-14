import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'data/issue_repository.dart';
import 'data/sqlite_issue_repository.dart';
import 'state/issues_provider.dart';
import 'ui/app_theme.dart';
import 'ui/screens/home_screen.dart';

class BairroEmDiaApp extends StatelessWidget {
  const BairroEmDiaApp({super.key, this.repository});
  final IssueRepository? repository;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<IssueRepository>(
        create: (_) => repository ?? SqliteIssueRepository(),
      ),
      ChangeNotifierProvider(
        create: (context) =>
            IssuesProvider(context.read<IssueRepository>())..load(),
      ),
    ],
    child: MaterialApp(
      title: 'Bairro em Dia',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    ),
  );
}
