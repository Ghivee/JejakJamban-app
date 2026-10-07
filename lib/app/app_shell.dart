import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Insight',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          selectedIcon: Icon(Icons.add_circle_rounded),
          label: 'Jejak',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events_rounded),
          label: 'Liga',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map_rounded),
          label: 'Peta',
        ),
      ],
    ),
  );
}
