import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Conversational, one-topic-at-a-time goal details (less form fatigue).
class GoalDetailsStep extends StatefulWidget {
  const GoalDetailsStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  GoalDetailsStepState createState() => GoalDetailsStepState();
}

class GoalDetailsStepState extends State<GoalDetailsStep> {
  int _page = 0;

  /// Returns true if this step handled back internally.
  bool tryGoBack() {
    if (_page > 0) {
      setState(() => _page--);
      return true;
    }
    return false;
  }

  List<_DetailPage> get _pages {
    final d = widget.draft;
    final pages = <_DetailPage>[];
    // Keep this light — one card per selected goal type.
    if (d.wantsWeightLoss) pages.add(_DetailPage.weight);
    if (d.wantsBetterSleep) pages.add(_DetailPage.sleep);
    if (d.wantsLessStress) pages.add(_DetailPage.stress);
    return pages;
  }

  Future<void> _pickTime(void Function(String) save, String? current) async {
    final parts = (current ?? '22:00').split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 22,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lavender,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => save(formatted));
  }

  void _advance() {
    if (_page >= _pages.length - 1) {
      widget.onContinue();
    } else {
      setState(() => _page++);
    }
  }

  void _next() {
    // Soft: allow continue even if unanswered — details are optional.
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onContinue());
      return const SizedBox.shrink();
    }

    final page = _pages[_page];
    final d = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingStepHeader(
          eyebrow: 'Goal details · ${_page + 1}/${_pages.length}',
          title: page.title,
          subtitle: page.subtitle,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: KeyedSubtree(
            key: ValueKey(page),
            child: _buildPage(page, d),
          ),
        ),
        OnboardingFooterButton(
          label: _page >= _pages.length - 1 ? 'Continue' : 'Next',
          onPressed: _next,
          onSkip: widget.onContinue,
          skipLabel: 'Skip details',
        ),
      ],
    );
  }

  Widget _buildPage(_DetailPage page, OnboardingDraft d) {
    switch (page) {
      case _DetailPage.weight:
        final options = _weightSuggestions(d);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final w in options)
              _BigSelectCard(
                label: '${w.toStringAsFixed(0)} ${d.weightUnit}',
                selected: d.targetWeight == w,
                onTap: () => setState(() => d.targetWeight = w),
              ),
          ],
        );
      case _DetailPage.sleep:
        return Column(
          children: [
            _TimeCard(
              label: 'Bedtime',
              value: d.preferredBedtime,
              onTap: () =>
                  _pickTime((v) => d.preferredBedtime = v, d.preferredBedtime),
            ),
            const SizedBox(height: 12),
            _TimeCard(
              label: 'Wake time',
              value: d.wakeTime,
              onTap: () => _pickTime((v) => d.wakeTime = v, d.wakeTime),
            ),
            const SizedBox(height: 16),
            OnboardingChipWrap(
              options: const ['7', '8', '9'],
              selected: {d.sleepGoalHours ?? '8'},
              multi: false,
              onToggle: (v) => setState(() => d.sleepGoalHours = v),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sleep goal (hours) — optional',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        );
      case _DetailPage.stress:
        return OnboardingChipWrap(
          options: OnboardingOptions.relaxationActivities,
          selected: d.relaxationActivities.toSet(),
          onToggle: (v) {
            setState(() {
              final list = [...d.relaxationActivities];
              if (list.contains(v)) {
                list.remove(v);
              } else {
                list.add(v);
              }
              d.relaxationActivities = list;
            });
          },
        );
    }
  }

  List<double> _weightSuggestions(OnboardingDraft d) {
    final current = d.weight ?? 70;
    return [
      (current - 2).clamp(30, 200).toDouble(),
      (current - 4).clamp(30, 200).toDouble(),
      (current - 6).clamp(30, 200).toDouble(),
      (current - 8).clamp(30, 200).toDouble(),
    ];
  }
}

enum _DetailPage { weight, sleep, stress }

extension on _DetailPage {
  String get title => switch (this) {
        _DetailPage.weight => 'Any target weight in mind?',
        _DetailPage.sleep => 'Want a sleep window?',
        _DetailPage.stress => 'What helps you unwind?',
      };

  String get subtitle => switch (this) {
        _DetailPage.weight => 'Optional — tap a suggestion or skip.',
        _DetailPage.sleep => 'Optional — set times or skip for now.',
        _DetailPage.stress => 'Optional — pick what helps, or skip.',
      };
}

class _BigSelectCard extends StatelessWidget {
  const _BigSelectCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? AppColors.lavender.withValues(alpha: 0.2)
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.lavender : AppColors.surfaceBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.lavenderBright : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value ?? 'Tap to set',
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.schedule_rounded, color: AppColors.lavender),
          ],
        ),
      ),
    );
  }
}
