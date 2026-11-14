import 'package:material_ui/material_ui.dart';

import '../screens/issue_list_screen.dart';
import '../screens/neighborhoods_screen.dart';

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      if (index == selectedIndex) return;
      if (index == 0) {
        Navigator.popUntil(context, (route) => route.isFirst);
        return;
      }
      final route = MaterialPageRoute<void>(
        builder: (_) =>
            index == 1 ? const IssueListScreen() : const NeighborhoodsScreen(),
      );
      if (selectedIndex == 0) {
        Navigator.push(context, route);
      } else {
        Navigator.pushReplacement(context, route);
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Início',
      ),
      NavigationDestination(
        icon: Icon(Icons.view_agenda_outlined),
        selectedIcon: Icon(Icons.view_agenda),
        label: 'Registros',
      ),
      NavigationDestination(
        icon: Icon(Icons.location_city_outlined),
        selectedIcon: Icon(Icons.location_city),
        label: 'Bairros',
      ),
    ],
  );
}
