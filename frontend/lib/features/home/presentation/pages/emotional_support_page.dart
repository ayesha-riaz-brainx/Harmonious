import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/entertainment_recommendations_page.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/breathing_exercise_modal.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/grounding_exercise_modal.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/pause_exercise_modal.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class _MantraItem {
  const _MantraItem(this.quote, this.detail);
  final String quote;
  final String detail;
}

class _FeelingItem {
  const _FeelingItem(this.label, this.message);
  final String label;
  final String message;
}

class _PracticeItem {
  const _PracticeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String kind;
}

const _kMantras = [
  _MantraItem(
    'You are allowed to rest.',
    'Progress includes pausing. Softness is strength.',
  ),
  _MantraItem(
    'This feeling is temporary.',
    'You’ve moved through hard moments before — you can again.',
  ),
  _MantraItem(
    'One breath is enough for now.',
    'You don’t have to fix everything today.',
  ),
  _MantraItem(
    'Be gentle with yourself.',
    'Talk to yourself the way you’d talk to a friend.',
  ),
  _MantraItem(
    'You are not behind.',
    'Your pace is valid. Showing up counts.',
  ),
  _MantraItem(
    'Small steps still move you.',
    'A sip of water, a stretch, a kind thought — all real.',
  ),
  _MantraItem(
    'You can hold hope and hard days together.',
    'Both can be true. You’re still worthy of care.',
  ),
  _MantraItem(
    'Your mind is not your enemy.',
    'It’s trying to protect you. Thank it, then soften.',
  ),
];

const _kFeelings = [
  _FeelingItem('Stressed', 'I am feeling stressed today.'),
  _FeelingItem('Anxious', 'I feel anxious and overwhelmed.'),
  _FeelingItem('Overwhelmed', 'Everything feels like too much right now.'),
  _FeelingItem('Low energy', 'I feel low and unmotivated.'),
  _FeelingItem('Can’t sleep', 'My mind won’t settle and I can’t sleep.'),
  _FeelingItem('Lonely', 'I feel alone and disconnected.'),
];

const _kPractices = [
  _PracticeItem(
    title: 'Breathing',
    subtitle: '4–4–6 guided breath',
    icon: Icons.air_rounded,
    kind: 'breathing',
  ),
  _PracticeItem(
    title: 'Grounding',
    subtitle: '5-4-3-2-1 senses',
    icon: Icons.spa_rounded,
    kind: 'grounding',
  ),
  _PracticeItem(
    title: 'Pause',
    subtitle: '2 quiet minutes',
    icon: Icons.self_improvement_rounded,
    kind: 'pause',
  ),
];

class EmotionalSupportPage extends StatefulWidget {
  const EmotionalSupportPage({super.key});

  @override
  State<EmotionalSupportPage> createState() => _EmotionalSupportPageState();
}

class _EmotionalSupportPageState extends State<EmotionalSupportPage> {
  final _api = FeatureService();
  final _message = TextEditingController();
  bool _busy = false;
  Map<String, dynamic>? _result;
  int _mantraIndex = 0;

  @override
  void initState() {
    super.initState();
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    _mantraIndex = day % _kMantras.length;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _nextMantra() {
    setState(() {
      _mantraIndex = (_mantraIndex + 1) % _kMantras.length;
    });
  }

  Future<void> _openExercise(String kind) async {
    switch (kind) {
      case 'breathing':
        await showBreathingExerciseModal(context);
      case 'grounding':
        await showGroundingExerciseModal(context);
      case 'pause':
        await showPauseExerciseModal(context);
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _message.text).trim();
    if (text.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _message.text = text;
      _result = null;
    });

    try {
      final data = await _api.post('ai/tool', {
        'tool': 'emotional_support',
        'input': {'text': text},
      });
      if (!mounted) return;
      final result = Map<String, dynamic>.from(data['result'] as Map? ?? {});
      final exercise = (result['exercise']?.toString() ?? 'none').toLowerCase();
      setState(() {
        _result = result;
        _busy = false;
      });

      if (exercise == 'breathing' ||
          exercise == 'grounding' ||
          exercise == 'pause') {
        await Future<void>.delayed(const Duration(milliseconds: 280));
        if (mounted) await _openExercise(exercise);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String get _ctaLabel {
    final exercise = (_result?['exercise']?.toString() ?? 'none').toLowerCase();
    return switch (exercise) {
      'grounding' => 'Start grounding 5-4-3-2-1',
      'pause' => 'Start 2-minute pause',
      'breathing' => 'Start breathing exercise',
      _ => 'Try a calming practice',
    };
  }

  String get _ctaKind {
    final exercise = (_result?['exercise']?.toString() ?? 'none').toLowerCase();
    if (exercise == 'grounding' ||
        exercise == 'pause' ||
        exercise == 'breathing') {
      return exercise;
    }
    return 'grounding';
  }

  @override
  Widget build(BuildContext context) {
    final mantra = _kMantras[_mantraIndex];

    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Emotional support'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            HarmoniousSpacing.screenHorizontal,
            4,
            HarmoniousSpacing.screenHorizontal,
            36,
          ),
          children: [
            HarmoniousCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A soft place to land',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Share how you feel, borrow a mantra, or open a practice. No judgment — only care.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            HarmoniousCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              accentColor: AppColors.cyanAccent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EntertainmentRecommendationsPage(
                      initialMood: 'stressed',
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.movie_filter_outlined,
                    color: AppColors.cyanAccent.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Want something to watch?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Optional gentle picks when you need a distraction.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),

            // Mantra of the day
            const SizedBox(height: 22),
            const HarmoniousSectionHeader(title: 'Mantra'),
            const SizedBox(height: 12),
            HarmoniousCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              onTap: _nextMantra,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap for another',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '“${mantra.quote}”',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      mantra.detail,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ),

            // More mantras strip
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kMantras.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = _kMantras[index];
                  final selected = index == _mantraIndex;
                  return InkWell(
                    onTap: () => setState(() => _mantraIndex = index),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 168,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.cardSurface,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.cardBorder.withValues(alpha: 0.85),
                        ),
                      ),
                      child: Text(
                        item.quote,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Feelings
            const SizedBox(height: 26),
            const _SectionLabel('How are you feeling?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final feeling in _kFeelings)
                  _FeelingChip(
                    label: feeling.label,
                    enabled: !_busy,
                    onTap: () => _send(feeling.message),
                  ),
              ],
            ),

            // Practices
            const SizedBox(height: 26),
            const _SectionLabel('Practices'),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < _kPractices.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _PracticeCard(
                      title: _kPractices[i].title,
                      subtitle: _kPractices[i].subtitle,
                      icon: _kPractices[i].icon,
                      enabled: !_busy,
                      onTap: () => _openExercise(_kPractices[i].kind),
                    ),
                  ),
                ],
              ],
            ),

            // Share
            const SizedBox(height: 26),
            const _SectionLabel('Talk it out'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.85),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _message,
                    minLines: 3,
                    maxLines: 5,
                    enabled: !_busy,
                    style: const TextStyle(height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'What’s weighing on you right now?',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : () => _send(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimaryButton,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimaryButton,
                              ),
                            )
                          : const Text(
                              'Get support',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Result
            if (_result != null) ...[
              const SizedBox(height: 20),
              _SupportResult(
                result: _result!,
                ctaLabel: _ctaLabel,
                ctaKind: _ctaKind,
                onPractice: () => _openExercise(_ctaKind),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.cardSurface,
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 132,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.cardSurface,
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.85),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportResult extends StatelessWidget {
  const _SupportResult({
    required this.result,
    required this.ctaLabel,
    required this.ctaKind,
    required this.onPractice,
  });

  final Map<String, dynamic> result;
  final String ctaLabel;
  final String ctaKind;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final actions =
        ((result['actions'] as List?) ?? []).map((e) => e.toString()).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.cardSurface,
        border: Border.all(
          color: AppColors.cardBorder.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result['title']?.toString() ?? 'Support',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result['summary']?.toString() ?? '',
            style: const TextStyle(height: 1.55, fontSize: 14.5),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPractice,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                ctaKind == 'breathing'
                    ? Icons.air_rounded
                    : ctaKind == 'pause'
                        ? Icons.self_improvement_rounded
                        : Icons.spa_rounded,
              ),
              label: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}
