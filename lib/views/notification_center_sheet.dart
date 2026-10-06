import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/design_system/design_system.dart';
import '../services/push_notification_service.dart';

/// Reusable Notification Bell with live unread badge.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class NotificationBadgeButton extends StatelessWidget {
  final String userId;
  final String? enterpriseId;
  final bool isAdmin;

  const NotificationBadgeButton({
    super.key,
    required this.userId,
    this.enterpriseId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusTheme = context.status;
    final textTheme = context.text;

    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: PushNotificationService().streamNotifications(
        userId: userId,
        enterpriseId: enterpriseId,
        isAdmin: isAdmin,
      ),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final unreadCount = notifications.where((n) {
          final data = n.data() as Map<String, dynamic>;
          return data['read'] != true;
        }).length;

        return IconButton(
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusTheme.danger.onContainer,
              ),
            ),
            backgroundColor: statusTheme.danger.color,
            child: const Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Notifications',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => NotificationCenterSheet(
                userId: userId,
                enterpriseId: enterpriseId,
                isAdmin: isAdmin,
              ),
            );
          },
        );
      },
    );
  }
}

/// Bottom sheet displaying in-app notification feed.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class NotificationCenterSheet extends StatelessWidget {
  final String userId;
  final String? enterpriseId;
  final bool isAdmin;

  const NotificationCenterSheet({
    super.key,
    required this.userId,
    this.enterpriseId,
    this.isAdmin = false,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'REGULARIZATION_REQUEST':
        return Icons.pending_actions_rounded;
      case 'REGULARIZATION_APPROVED':
        return Icons.check_circle_rounded;
      case 'REGULARIZATION_REJECTED':
        return Icons.cancel_rounded;
      case 'GEOFENCE_BREACH':
        return Icons.location_off_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(BuildContext context, String? type) {
    final statusTheme = context.status;
    final colors = context.colors;
    switch (type) {
      case 'REGULARIZATION_REQUEST':
        return statusTheme.warning.color;
      case 'REGULARIZATION_APPROVED':
        return statusTheme.success.color;
      case 'REGULARIZATION_REJECTED':
        return statusTheme.danger.color;
      case 'GEOFENCE_BREACH':
        return statusTheme.danger.color;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.notifications_active_outlined, color: colors.primary, size: AppSizes.iconMd),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isAdmin ? 'Admin Alerts' : 'Notifications',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: PushNotificationService().streamNotifications(
                        userId: userId,
                        enterpriseId: enterpriseId,
                        isAdmin: isAdmin,
                      ),
                      builder: (context, snapshot) {
                        final unreadDocs = (snapshot.data ?? [])
                            .where((d) => (d.data() as Map<String, dynamic>)['read'] != true)
                            .map((d) => d.id)
                            .toList();

                        if (unreadDocs.isEmpty) return const SizedBox.shrink();

                        return TextButton.icon(
                          onPressed: () {
                            PushNotificationService().markAllAsRead(unreadDocs);
                          },
                          icon: const Icon(Icons.done_all_rounded, size: AppSizes.iconSm),
                          label: Text('Mark all read', style: textTheme.labelSmall),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),

              // Notification List
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: PushNotificationService().streamNotifications(
                    userId: userId,
                    enterpriseId: enterpriseId,
                    isAdmin: isAdmin,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppListSkeleton(itemCount: 4);
                    }

                    final docs = snapshot.data ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: EmptyStateView(
                          icon: Icons.notifications_none_rounded,
                          title: 'No notifications yet',
                          message: isAdmin
                              ? 'Alerts for punch anomalies and regularizations will appear here.'
                              : 'Updates about your shifts and regularizations will appear here.',
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title'] as String? ?? 'Notification';
                        final body = data['body'] as String? ?? '';
                        final type = data['type'] as String?;
                        final isRead = data['read'] == true;
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        final color = _getTypeColor(context, type);
                        final icon = _getTypeIcon(type);

                        return Material(
                          color: isRead
                              ? colors.surfaceContainerHighest.withValues(alpha: 0.2)
                              : color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () {
                              if (!isRead) {
                                PushNotificationService().markAsRead(doc.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: color.withValues(alpha: 0.15),
                                    child: Icon(icon, color: color, size: AppSizes.iconMd),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: textTheme.titleSmall?.copyWith(
                                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                  color: colors.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.xs),
                                            Text(
                                              _formatTime(createdAt),
                                              style: textTheme.labelSmall?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        Text(
                                          body,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colors.onSurfaceVariant,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
