import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.fullName ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? user?.phone ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: Text(user?.language.toUpperCase() ?? 'EN'),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            trailing: Text(user?.currency ?? 'USD'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              ref.invalidate(authStateProvider);
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
