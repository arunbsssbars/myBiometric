import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/enterprise_announcement.dart';

/// Responsive card displaying pinned enterprise announcements with priority badges.
class AnnouncementBannerCard extends StatelessWidget {
  final EnterpriseAnnouncement announcement;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const AnnouncementBannerCard({
    super.key,
    required this.announcement,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${announcement.publishedAt.year}-${announcement.publishedAt.month.toString().padLeft(2, '0')}-${announcement.publishedAt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: announcement.priorityColor.withAlpha(announcement.priority == AnnouncementPriority.urgent ? 120 : 60),
          width: announcement.priority == AnnouncementPriority.urgent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: announcement.priorityColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(announcement.priorityIcon, size: 18, color: announcement.priorityColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${announcement.authorName} • $dateStr',
                      style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            announcement.message,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
