import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../core/design_system/design_system.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> with WidgetsBindingObserver {
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Periodically poll every 3 seconds to detect verification without manual clicks
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkStatus(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned from email app or web redirect; check immediately
      _checkStatus(silent: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_isChecking && !silent) return;
    if (!silent) setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null && refreshedUser.emailVerified) {
          _periodicCheckTimer?.cancel();
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Email verified successfully! Welcome to myBiometric.'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (!silent && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not yet verified. Please click the link sent to your inbox.'),
            backgroundColor: Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification check failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendLink() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);

    try {
      final success = await AuthService().sendEmailVerification();
      _startCooldown();
      if (mounted && context.mounted) {
        final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Verification email resent to $email' : 'Failed to resend. Please try again shortly.'),
            backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              AppThemeNotifier.instance.setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.mark_email_unread_rounded, size: 48, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to:\n${user?.email ?? "your email address"}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Click the link in the email to return to myBiometric automatically.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : () => _checkStatus(silent: false),
                      icon: _isChecking
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _isChecking ? 'Verifying...' : "I've Verified, Continue",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: (_resendCooldown > 0 || _isResending) ? null : _resendLink,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : (_isResending ? 'Sending...' : 'Resend Verification Link'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => AuthService().signOut(),
                    child: const Text(
                      'Sign Out / Use a different account',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
