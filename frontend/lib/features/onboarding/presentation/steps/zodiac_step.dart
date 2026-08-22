import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/astrology/zodiac_sign.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Optional: birthday auto-calculates sign, or pick manually.
class ZodiacStep extends StatefulWidget {
  const ZodiacStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<ZodiacStep> createState() => _ZodiacStepState();
}

class _ZodiacStepState extends State<ZodiacStep> {
  bool _manualPick = false;

  ZodiacSign? get _selected {
    if (widget.draft.zodiacSign != null) {
      return ZodiacSign.fromId(widget.draft.zodiacSign);
    }
    if (widget.draft.birthday != null) {
      return ZodiacSign.fromBirthday(widget.draft.birthday!);
    }
    return null;
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = widget.draft.birthday ??
        DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Your birthday',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      widget.draft.birthday = picked;
      final sign = ZodiacSign.fromBirthday(picked);
      if (sign != null) {
        widget.draft.zodiacSign = sign.id;
      }
      _manualPick = false;
    });
  }

  void _selectSign(ZodiacSign sign) {
    setState(() {
      widget.draft.zodiacSign = sign.id;
      _manualPick = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Cosmic profile',
          title: "What's your sign?",
          subtitle:
              'We use it for a daily wellness check-in — not generic horoscopes. '
              'Pick your sign or use your birthday.',
        ),
        OutlinedButton.icon(
          onPressed: _pickBirthday,
          icon: const Icon(Icons.cake_outlined, size: 18),
          label: Text(
            widget.draft.birthday == null
                ? 'Use my birthday'
                : 'Birthday: ${_formatDate(widget.draft.birthday!)}',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.surfaceBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (selected != null && !_manualPick && widget.draft.birthday != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Calculated: ${selected.symbol} ${selected.label}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Or choose your sign',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            for (final sign in ZodiacSign.values)
              _SignTile(
                sign: sign,
                selected: selected == sign,
                onTap: () => _selectSign(sign),
              ),
          ],
        ),
        const SizedBox(height: 24),
        OnboardingFooterButton(
          label: selected == null ? 'Skip for now' : 'Continue',
          onPressed: widget.onContinue,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SignTile extends StatelessWidget {
  const _SignTile({
    required this.sign,
    required this.selected,
    required this.onTap,
  });

  final ZodiacSign sign;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.14)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.surfaceBorder,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                sign.symbol,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 4),
              Text(
                sign.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
