import 'package:flutter/material.dart';
import '../../domain/models/mobile_terminal_handshake_ticket.dart';
import '../../services/mobile_terminal_handshake_service.dart';

/// Modal dialog performing and displaying a zero-trust mutual authentication handshake with a physical biometric machine
class MobileTerminalHandshakeDialog extends StatefulWidget {
  final String terminalId;
  final String terminalName;
  final String employeeId;
  final String enterpriseId;

  const MobileTerminalHandshakeDialog({
    super.key,
    required this.terminalId,
    this.terminalName = 'Main Biometric Reader',
    required this.employeeId,
    required this.enterpriseId,
  });

  @override
  State<MobileTerminalHandshakeDialog> createState() =>
      _MobileTerminalHandshakeDialogState();
}

class _MobileTerminalHandshakeDialogState
    extends State<MobileTerminalHandshakeDialog> {
  final MobileTerminalHandshakeService _service =
      MobileTerminalHandshakeService();
  bool _isAuthenticating = false;
  MobileTerminalHandshakeTicket? _ticket;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _executeHandshake();
  }

  Future<void> _executeHandshake() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // Simulate cryptographic challenge exchange with hardware terminal over Bluetooth/LAN
      await Future.delayed(const Duration(milliseconds: 600));

      final nonce =
          'NONCE_${DateTime.now().microsecondsSinceEpoch.toRadixString(16).toUpperCase()}';
      final ticket = _service.completeHandshake(
        terminalId: widget.terminalId,
        employeeId: widget.employeeId,
        terminalChallengeNonce: nonce,
      );

      final isValid = _service.verifyProof(ticket: ticket);
      if (!isValid) {
        throw Exception('Cryptographic signature verification failed.');
      }

      if (mounted) {
        setState(() {
          _ticket = ticket;
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.security_rounded, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Terminal Trust Handshake',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Machine: ${widget.terminalName} (${widget.terminalId})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (_isAuthenticating) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Exchanging cryptographic challenge nonce...'),
                    ],
                  ),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: colors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colors.error),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_ticket != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mutual Auth Established',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Session Key: ${_ticket!.sessionSharedSecretHex}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires in: ${_ticket!.remainingSeconds}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_errorMessage != null)
          TextButton(
            onPressed: _executeHandshake,
            child: const Text('Retry'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ticket != null),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
