import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty && _phoneCtrl.text.isEmpty) {
      setState(() => _error = 'Please provide an email or phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).register(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.isNotEmpty ? _emailCtrl.text.trim() : null,
        phone: _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text.trim() : null,
        password: _passwordCtrl.text,
      );
      ref.invalidate(authStateProvider);
      if (mounted) context.go('/agent');
    } catch (e) {
      setState(() => _error = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'CheckinCheckOut',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Text('Create account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              Text('Start booking with your AI travel agent',
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'optional if phone provided',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '+77001234567 — optional if email provided',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Min. 8 characters',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create account'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Sign in',
                        style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
