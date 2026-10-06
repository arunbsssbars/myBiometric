import 'package:flutter/material.dart';
import '../services/ultrasonic_punch_chirp_service.dart';

/// Card component for triggering ultrasonic sound chirp to machine microphone
class UltrasonicPunchChirpCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;

  const UltrasonicPunchChirpCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
  });

  @override
  State<UltrasonicPunchChirpCard> createState() => _UltrasonicPunchChirpCardState();
}

class _UltrasonicPunchChirpCardState extends State<UltrasonicPunchChirpCard> {
  late final UltrasonicPunchChirpService _service;
  bool _isPlaying = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _service = UltrasonicPunchChirpService();
  }

  Future<void> _emitChirp() async {
    setState(() {
      _isPlaying = true;
      _statusText = 'Emitting near-ultrasonic acoustic pairing chirp (18.5 kHz)...';
    });

    final chirp = _service.generateChirp(
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
    );

    await Future.delayed(const Duration(milliseconds: 750));

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _statusText = 'Acoustic chirp transmitted to terminal microphone [${chirp.encryptedTonePayload}]';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.surround_sound_rounded,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ultrasonic Audio Chirp',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Touchless acoustic pairing with machine mic',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _isPlaying ? null : _emitChirp,
                icon: _isPlaying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volume_up_rounded, size: 18),
                label: const Text('Emit Acoustic Chirp Punch'),
              ),
            ),
            if (_statusText != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
