import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

/// Harmonious layout tokens — use across tabs, sheets, and standalone pages.
abstract final class HarmoniousSpacing {
  static const sectionGap = 24.0;
  static const cardPadding = 16.0;
  static const cardRadius = 16.0;
  static const screenHorizontal = 20.0;
  static const minTapTarget = 44.0;
}

/// Unified section title used on Today, Journey, AI, and detail pages.
class HarmoniousSectionHeader extends StatelessWidget {
  const HarmoniousSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        );

    if (subtitle == null && trailing == null) {
      return Text(title, style: titleStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
          ),
        ],
      ],
    );
  }
}

/// Tab-level page header (icon + title + subtitle).
class HarmoniousPageHeader extends StatelessWidget {
  const HarmoniousPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.primaryBright,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
            ),
          ],
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

/// Dark card with consistent padding, radius, and optional accent tint.
class HarmoniousCard extends StatelessWidget {
  const HarmoniousCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(HarmoniousSpacing.cardPadding),
    this.accentColor,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? accentColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(HarmoniousSpacing.cardRadius);
    final accent = accentColor;

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: accent == null
            ? AppColors.cardSurface
            : Color.alphaBlend(
                accent.withValues(alpha: 0.07),
                AppColors.cardSurface,
              ),
        borderRadius: radius,
        border: Border.all(
          color: accent == null
              ? AppColors.cardBorder.withValues(alpha: 0.85)
              : accent.withValues(alpha: 0.42),
        ),
      ),
      child: child,
    );

    if (onTap == null) return card;

    return HarmoniousPressable(
      onTap: onTap,
      borderRadius: radius,
      child: card,
    );
  }
}

/// Icon + message + optional CTA for empty lists and error recovery.
class HarmoniousEmptyState extends StatelessWidget {
  const HarmoniousEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 8 : 12,
        horizontal: compact ? 0 : 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: compact ? 22 : 26,
              color: AppColors.primaryBright,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: compact ? 13 : 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Subtle scale-down press feedback for tappable cards and links.
class HarmoniousPressable extends StatefulWidget {
  const HarmoniousPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double scale;

  @override
  State<HarmoniousPressable> createState() => _HarmoniousPressableState();
}

class _HarmoniousPressableState extends State<HarmoniousPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: widget.borderRadius,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Thin divider between major sections on Journey / You tabs.
class HarmoniousSectionDivider extends StatelessWidget {
  const HarmoniousSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.cardBorder.withValues(alpha: 0.65),
      ),
    );
  }
}

/// Cyan text link for inline actions (Log water, History, etc.).
class HarmoniousActionLink extends StatelessWidget {
  const HarmoniousActionLink({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HarmoniousPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      scale: 0.94,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onTap == null ? AppColors.textMuted : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

/// Standard error + retry block for full-screen states.
class HarmoniousErrorState extends StatelessWidget {
  const HarmoniousErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.hint,
  });

  final String message;
  final VoidCallback onRetry;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HarmoniousEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Something went wrong',
              message: message,
              compact: true,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standalone feature page scaffold with transparent app bar.
class HarmoniousDetailScaffold extends StatelessWidget {
  const HarmoniousDetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.actions,
    this.loading = false,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        actions: actions,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : body,
    );
  }
}

/// Full-width primary CTA row matching Today tab actions.
class HarmoniousPrimaryChipButton extends StatelessWidget {
  const HarmoniousPrimaryChipButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HarmoniousPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      scale: 0.96,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.cyanGradientStart,
              AppColors.cyanGradientEnd,
            ],
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.onPrimaryButton,
              ),
        ),
      ),
    );
  }
}

/// Outlined secondary action matching Today tab.
class HarmoniousSecondaryChipButton extends StatelessWidget {
  const HarmoniousSecondaryChipButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HarmoniousPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}
