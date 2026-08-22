import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_agreeToTerms) return;
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    await ref.read(authControllerProvider.notifier).registerWithEmail(email, password, name);
    if (!mounted) return;
    
    final authState = ref.read(authControllerProvider);
    if (authState.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.error.toString()), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    'Expert',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Money',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              SizedBox(height: 48),
              Text('Create account', style: Theme.of(context).textTheme.displayMedium),
              SizedBox(height: 8),
              Text('Start planning in under a minute.', style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 48),
              Text('Full name', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'David Pop',
                ),
              ),
              SizedBox(height: 24),
              Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'john@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 24),
              Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: TextButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Text(_obscurePassword ? 'Show' : 'Hide'),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms and Privacy Policy.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_agreeToTerms && !ref.watch(authControllerProvider).isLoading) ? _register : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.black38,
                  ),
                  child: ref.watch(authControllerProvider).isLoading
                      ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface)
                      : Text('Create account'),
                ),
              ),
              SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('Sign in'),
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
