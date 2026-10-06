import 'package:flutter/material.dart';
import '../domain/models/mobile_selfie_terminal_enrollment.dart';
import '../services/mobile_selfie_terminal_enrollment_service.dart';

/// Card component for capturing selfie on mobile and syncing face profile to physical terminals
class MobileSelfieTerminalEnrollmentCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;
  final String employeeName;

  const MobileSelfieTerminalEnrollmentCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
    required this.employeeName,
  });

  @override
  State<MobileSelfieTerminalEnrollmentCard> createState() =>
      _MobileSelfieTerminalEnrollmentCardState();
}

class _MobileSelfieTerminalEnrollmentCardState
    extends State<MobileSelfieTerminalEnrollmentCard> {
  late final MobileSelfieTerminalEnrollmentService _service;
  bool _isSyncing = false;
  bool _isEnrolled = false;

  @override
  void initState() {
    super.initState();
    _service = MobileSelfieTerminalEnrollmentService();
  }

  Future<void> _handleCaptureAndSync() async {
    setState(() => _isSyncing = true);

    // Simulated 128-d mock embedding & jpeg base64
    final dummyEmbeddings = List.generate(128, (i) => 0.05 * (i % 5));
    final enrollment = MobileSelfieTerminalEnrollment(
      enrollmentId: 'ENR_${DateTime.now().millisecondsSinceEpoch}',
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
      employeeName: widget.employeeName,
      base64FaceJpeg: 'data:image/jpeg;base64,' + 'A' * 600,
      faceFeatureVector: dummyEmbeddings,
      enrolledAt: DateTime.now(),
    );

    final result = await _service.syncEnrollmentToTerminals(enrollment);

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _isEnrolled = result.isSyncedToHikvisionMinMoe && result.isSyncedToZkTecoAdms;
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
                    color: _isEnrolled
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    color: _isEnrolled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selfie Terminal Sync',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isEnrolled
                            ? 'Face profile active on all physical terminals'
                            : 'Snap selfie to auto-register face on machine',
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
                onPressed: _isSyncing ? null : _handleCaptureAndSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEnrolled ? Icons.check_circle_outline : Icons.camera_alt_outlined, size: 18),
                label: Text(_isEnrolled ? 'Re-enroll Machine Face' : 'Snap Selfie & Sync to Machine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
