import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/shell/app_shell.dart';
import '../../features/agent/screens/agent_screen.dart';
import '../../features/flights/screens/flight_search_screen.dart';
import '../../features/flights/screens/flight_results_screen.dart';
import '../../features/bookings/screens/bookings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

const _protectedRoutes = ['/bookings', '/profile'];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/flights',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/login') || loc.startsWith('/register');
      final isProtected = _protectedRoutes.any((r) => loc.startsWith(r));
      if (!isAuthenticated && isProtected) return '/login';
      if (isAuthenticated && isAuthRoute) return '/flights';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Results — outside shell (full screen)
      GoRoute(
        path: '/flights/results',
        builder: (_, state) => FlightResultsScreen(
          params: (state.extra as Map<String, dynamic>?) ?? {},
        ),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/agent', builder: (_, __) => const AgentScreen()),
          GoRoute(path: '/flights', builder: (_, __) => const FlightSearchScreen()),
          GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
