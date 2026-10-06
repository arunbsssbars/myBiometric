import 'package:flutter/material.dart';

import '../design_system.dart';

/// Card header: tinted icon badge + title + optional subtitle + trailing slot.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppRadius.brMd),
          child: Icon(icon, color: colors.primary, size: AppSizes.iconMd),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

/// Compact status badge (icon + label) — never color-only.
class StatusPill extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final IconData? icon;

  const StatusPill({super.key, required this.label, required this.tone, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: tone.container,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone.onContainer),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: tone.onContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// KPI tile: large count + label + optional secondary note.
class KpiTile extends StatelessWidget {
  final String label;
  final int count;
  final StatusTone tone;
  final IconData icon;
  final String? note;
  final StatusTone? noteTone;

  const KpiTile({
    super.key,
    required this.label,
    required this.count,
    required this.tone,
    required this.icon,
    this.note,
    this.noteTone,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $count${note != null ? ', $note' : ''}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: tone.container,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: tone.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: tone.onContainer),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    '$count',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium?.copyWith(
                      color: tone.onContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.labelSmall?.copyWith(
                color: tone.onContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: (noteTone ?? context.status.danger).onContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state: icon + headline + optional message + optional action.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: colors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.titleSmall?.copyWith(color: colors.onSurface),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Error state with a human-readable message and Retry action.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final danger = context.status.danger;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: danger.container,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: danger.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: danger.onContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: danger.onContainer),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Shimmer container providing subtle pulsing placeholder animations.
class AppShimmer extends StatefulWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.45 + (0.55 * _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Lightweight skeleton block used for loading placeholders.
class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: borderRadius ?? AppRadius.brSm,
      ),
    );
  }
}

/// Standardized list skeleton loader for cards or list items.
class AppListSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const AppListSkeleton({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerLowest,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Row(
            children: [
              SkeletonBox(
                height: 40,
                width: 40,
                borderRadius: AppRadius.brPill,
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 140),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(height: 10, width: 90),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const SkeletonBox(height: 24, width: 60),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized card skeleton loader.
class AppCardSkeleton extends StatelessWidget {
  final double height;

  const AppCardSkeleton({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(height: 16, width: 120),
                Spacer(),
                SkeletonBox(height: 20, width: 50),
              ],
            ),
            Spacer(),
            SkeletonBox(height: 24, width: 80),
            SizedBox(height: AppSpacing.xs),
            SkeletonBox(height: 12, width: 160),
          ],
        ),
      ),
    );
  }
}

/// Centers content and caps width on large displays, with responsive gutters per M3 window class.
class AdaptiveContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? paddingOverride;

  const AdaptiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.maxContentWidth,
    this.paddingOverride,
  });

  @override
  Widget build(BuildContext context) {
    final windowSize = context.windowSize;
    final EdgeInsetsGeometry padding = paddingOverride ??
        switch (windowSize) {
          WindowSizeClass.compact => const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          WindowSizeClass.medium => const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          WindowSizeClass.expanded || WindowSizeClass.large => const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        };

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Adaptive layout builder switching between compact, medium, and expanded UI variants.
class AdaptiveWindowLayout extends StatelessWidget {
  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  const AdaptiveWindowLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = AppBreakpoints.of(constraints.maxWidth);
        if (windowClass.isAtLeastExpanded && expanded != null) {
          return expanded!(context);
        }
        if (windowClass.isAtLeastMedium && medium != null) {
          return medium!(context);
        }
        return compact(context);
      },
    );
  }
}
