import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.progress,
    this.onBack,
    this.showProgress = true,
  });

  final Widget child;
  final double progress;
  final VoidCallback? onBack;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final horizontal = media.size.width < 360 ? 20.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: HarmoniousBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 0),
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: showProgress
                          ? TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress.clamp(0.05, 1)),
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    minHeight: 6,
                                    backgroundColor: AppColors.surfaceBorder,
                                    color: AppColors.lavender,
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        18,
                        horizontal,
                        20 + media.viewInsets.bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 20,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.lavenderBright,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class OnboardingChipWrap extends StatelessWidget {
  const OnboardingChipWrap({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.multi = true,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String value) onToggle;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          _AnimatedChip(
            delay: i * 40,
            label: options[i],
            selected: selected.contains(options[i]),
            onTap: () => onToggle(options[i]),
          ),
      ],
    );
  }
}

class MoodChipWrap extends StatelessWidget {
  const MoodChipWrap({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<(String, String)> options;
  final Set<String> selected;
  final void Function(String label) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < options.length; i++)
          _AnimatedChip(
            delay: i * 45,
            label: '${options[i].$1}  ${options[i].$2}',
            selected: selected.contains(options[i].$2),
            onTap: () => onToggle(options[i].$2),
          ),
      ],
    );
  }
}

class _AnimatedChip extends StatefulWidget {
  const _AnimatedChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.delay = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int delay;

  @override
  State<_AnimatedChip> createState() => _AnimatedChipState();
}

class _AnimatedChipState extends State<_AnimatedChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: widget.selected
                  ? AppColors.lavender.withValues(alpha: 0.18)
                  : AppColors.surface,
              border: Border.all(
                color: widget.selected
                    ? AppColors.lavender
                    : AppColors.surfaceBorder,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: AppColors.lavender.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.selected
                    ? AppColors.lavenderBright
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingFooterButton extends StatelessWidget {
  const OnboardingFooterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.onSkip,
    this.skipLabel = 'Skip for now',
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          HarmoniousGradientButton(
            label: label,
            isLoading: isLoading,
            onPressed: onPressed,
          ),
          if (onSkip != null) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: isLoading ? null : onSkip,
              child: Text(
                skipLabel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OnboardingFieldLabel extends StatelessWidget {
  const OnboardingFieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// Shared page transition for step content.
Widget onboardingPageTransition(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0.06),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
