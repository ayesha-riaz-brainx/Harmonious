import 'package:flutter/material.dart';

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
  const _FeelingItem({
    required this.label,
    required this.title,
    required this.summary,
    required this.actions,
    required this.practice,
  });

  final String label;
  final String title;
  final String summary;
  final List<String> actions;
  final String practice;
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
  _FeelingItem(
    label: 'Stressed',
    title: 'Stress is loud — you can still choose one small calm',
    summary:
        'Your body is asking for a slower pace. You don’t need to solve everything; one grounding step is enough right now.',
    actions: [
      'Unclench your jaw and drop your shoulders',
      'Drink a glass of water slowly',
      'Name one thing you can leave for later',
    ],
    practice: 'breathing',
  ),
  _FeelingItem(
    label: 'Anxious',
    title: 'Anxiety wants urgency — answer with presence',
    summary:
        'Racing thoughts are trying to keep you safe. Bring attention back to what’s real in this room.',
    actions: [
      'Feel your feet on the floor',
      'Look around and name 3 colors you see',
      'Take one longer exhale than inhale',
    ],
    practice: 'grounding',
  ),
  _FeelingItem(
    label: 'Overwhelmed',
    title: 'Too much is still too much — shrink the next step',
    summary:
        'When everything piles up, your nervous system needs less input, not more effort.',
    actions: [
      'Write the top 1 task only',
      'Silence one notification for 10 minutes',
      'Sit still for two quiet minutes',
    ],
    practice: 'pause',
  ),
  _FeelingItem(
    label: 'Low energy',
    title: 'Low energy is information, not failure',
    summary:
        'Rest can be productive. Meet yourself at the energy you have today.',
    actions: [
      'Dim the lights or sit somewhere softer',
      'Eat or drink something simple',
      'Stretch for 30 seconds if that feels possible',
    ],
    practice: 'pause',
  ),
  _FeelingItem(
    label: 'Can’t sleep',
    title: 'A restless mind settles with rhythm',
    summary:
        'Trying to force sleep often backfires. Soften the body first and let the mind follow.',
    actions: [
      'Put the phone face-down',
      'Breathe in for 4, out for 6 a few times',
      'Keep lights low and avoid problem-solving in bed',
    ],
    practice: 'breathing',
  ),
  _FeelingItem(
    label: 'Lonely',
    title: 'Loneliness is real — connection can be gentle',
    summary:
        'Feeling alone doesn’t mean you’re unwanted. A small warm action can reopen a door.',
    actions: [
      'Send a short “thinking of you” message',
      'Sit with a calming show or playlist',
      'Write one kind sentence to yourself',
    ],
    practice: 'grounding',
  ),
];

const _kPractices = [
  _PracticeItem(
    title: 'Breathing',
    subtitle: '4-4-6 guided breath',
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
  int _mantraIndex = 0;
  _FeelingItem? _selectedFeeling;

  @override
  void initState() {
    super.initState();
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    _mantraIndex = day % _kMantras.length;
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

  String _practiceLabel(String kind) {
    return switch (kind) {
      'grounding' => 'Start grounding 5-4-3-2-1',
      'pause' => 'Start 2-minute pause',
      'breathing' => 'Start breathing exercise',
      _ => 'Try a calming practice',
    };
  }

  @override
  Widget build(BuildContext context) {
    final mantra = _kMantras[_mantraIndex];
    final feeling = _selectedFeeling;

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
                    'Pick how you feel, borrow a mantra, or open a short practice. No chat — just calm tools.',
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Optional gentle picks when you need a distraction.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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

            const SizedBox(height: 26),
            const _SectionLabel('How are you feeling?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in _kFeelings)
                  _FeelingChip(
                    label: item.label,
                    selected: feeling?.label == item.label,
                    onTap: () => setState(() => _selectedFeeling = item),
                  ),
              ],
            ),
            if (feeling != null) ...[
              const SizedBox(height: 14),
              _FeelingSupportCard(
                feeling: feeling,
                practiceLabel: _practiceLabel(feeling.practice),
                onPractice: () => _openExercise(feeling.practice),
              ),
            ],

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
                      onTap: () => _openExercise(_kPractices[i].kind),
                    ),
                  ),
                ],
              ],
            ),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.cardSurface,
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.cardBorder.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeelingSupportCard extends StatelessWidget {
  const _FeelingSupportCard({
    required this.feeling,
    required this.practiceLabel,
    required this.onPractice,
  });

  final _FeelingItem feeling;
  final String practiceLabel;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
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
                  feeling.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feeling.summary,
            style: const TextStyle(height: 1.55, fontSize: 14.5),
          ),
          const SizedBox(height: 14),
          for (final action in feeling.actions)
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
          const SizedBox(height: 6),
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
                feeling.practice == 'breathing'
                    ? Icons.air_rounded
                    : feeling.practice == 'pause'
                        ? Icons.self_improvement_rounded
                        : Icons.spa_rounded,
              ),
              label: Text(practiceLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
