import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService().signInWithEmail(email, password);
      } else {
        await AuthService().registerWithEmail(email, password);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        final isNetwork = e is AuthNetworkException ||
            e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('internet');
        final message = e is AuthException ? e.message : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (isNetwork)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  ),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: isNetwork ? Colors.orange.shade800 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint, size: 76, color: Color(0xFF2563EB)),
                    const SizedBox(height: 16),
                    Text(
                      'myBiometric',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? 'Employee Sign In' : 'Employee Registration',
                      style: TextStyle(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 36),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin ? 'Need an account? Register here.' : 'Already have an account? Sign In.'),
                    ),
                    const Divider(height: 36),
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final cred = await AuthService().signInWithGoogle();
                                if (cred == null && mounted) {
                                  setState(() => _isLoading = false);
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  final isNetwork = e is AuthNetworkException ||
                                      e.toString().toLowerCase().contains('network') ||
                                      e.toString().toLowerCase().contains('internet');
                                  final message = e is AuthException
                                      ? e.message
                                      : 'Google Sign-In failed: $e';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          if (isNetwork)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 8.0),
                                              child: Icon(Icons.wifi_off, color: Colors.white, size: 20),
                                            ),
                                          Expanded(child: Text(message)),
                                        ],
                                      ),
                                      backgroundColor: isNetwork ? Colors.orange.shade800 : Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted && _isLoading) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Continue with Google'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
