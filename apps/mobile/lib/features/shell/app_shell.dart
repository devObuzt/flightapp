import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    (icon: Icons.smart_toy_outlined, label: 'Agent', path: '/agent'),
    (icon: Icons.flight_outlined, label: 'Flights', path: '/flights'),
    (icon: Icons.book_outlined, label: 'Bookings', path: '/bookings'),
    (icon: Icons.person_outline, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
