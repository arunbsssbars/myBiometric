import 'package:flutter/material.dart';
import '../services/liveness_challenge_engine_service.dart';
import '../core/design_system/design_system.dart';

class LivenessChallengeProgressCard extends StatelessWidget {
  final LivenessChallengeSession session;
  final VoidCallback? onRetry;

  const LivenessChallengeProgressCard({
    super.key,
    required this.session,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentStep = session.currentStep;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: session.isFailed
              ? colors.error
              : session.isCompleted
                  ? Colors.green
                  : colors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  session.isFailed
                      ? Icons.cancel_rounded
                      : session.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.motion_photos_on_rounded,
                  color: session.isFailed
                      ? colors.error
                      : session.isCompleted
                          ? Colors.green
                          : colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.isCompleted
                        ? 'Liveness Verified'
                        : session.isFailed
                            ? 'Liveness Check Failed'
                            : 'Challenge ${session.currentStepIndex + 1} of ${session.steps.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(session.progressPercentage * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: session.progressPercentage,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                session.isFailed ? colors.error : colors.primary,
              ),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 10),
            Text(
              session.isFailed
                  ? (session.failureReason ?? 'Verification failed. Try again.')
                  : (currentStep?.instruction ?? 'Challenge complete.'),
              style: TextStyle(
                fontSize: 13,
                color: session.isFailed ? colors.error : colors.onSurfaceVariant,
                fontWeight: session.isFailed ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (session.isFailed && onRetry != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: colors.primary),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
