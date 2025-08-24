import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trello/provider/app_provider.dart';

class AppView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              );
            } else {
              return TextStyle(
                color: Colors.blueGrey,
              );
            }
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(index);
          },
          indicatorColor: Colors.transparent,
          destinations: [
            _menuItem(
              context,
              index: 0,
              currentIndex: navigationShell.currentIndex,
              label: l10n.boards,
              icon: Icons.border_all_rounded,
            ),
            _menuItem(
              context,
              index: 1,
              currentIndex: navigationShell.currentIndex,
              label: l10n.createBoard,
              icon: Icons.add_circle_outline,
            ),
            _menuItem(
              context,
              index: 2,
              currentIndex: navigationShell.currentIndex,
              label: l10n.myBoards,
              icon: Icons.bookmark_border_outlined,
            ),
            _menuItem(
              context,
              index: 3,
              currentIndex: navigationShell.currentIndex,
              label: l10n.account,
              icon: Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = currentIndex == index;
    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected
            ? Colors.blue[600]
            : Colors.blueGrey,
      ),
      label: label,
    );
  }
}