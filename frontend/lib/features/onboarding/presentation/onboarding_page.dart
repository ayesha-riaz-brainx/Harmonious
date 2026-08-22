import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/services/onboarding_service.dart';
import 'package:slot_1_tasks/core/services/profile_service.dart';
import 'package:slot_1_tasks/features/onboarding/data/ai_profile_builder.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/food_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/goal_details_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/goals_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/habits_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/health_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/pulse_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/summary_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/steps/zodiac_step.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Short conversational flow (~2 min).
/// Required: Goals (at least one). Everything else is skippable.
enum _Step {
  welcome,
  goals,
  goalDetails,
  pulse,
  zodiac,
  habits,
  health,
  food,
  summary,
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _profiles = ProfileService();
  final _onboarding = OnboardingService();
  final _builder = const AiProfileBuilder();
  final _goalDetailsKey = GlobalKey<GoalDetailsStepState>();

  late OnboardingDraft _draft;
  AiProfile? _profile;
  _Step _step = _Step.welcome;
  bool _loading = false;
  bool _ready = false;

  static const _ordered = [
    _Step.welcome,
    _Step.goals,
    _Step.goalDetails,
    _Step.pulse,
    _Step.zodiac,
    _Step.habits,
    _Step.health,
    _Step.food,
    _Step.summary,
  ];

  @override
  void initState() {
    super.initState();
    _draft = OnboardingDraft();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final profile = await _profiles.fetchCurrentProfile();
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        _draft.age = profile.age;
        _draft.gender = profile.gender;
        _draft.height = profile.height;
        _draft.weight = profile.weight;
        _draft.heightUnit = profile.heightUnit;
        _draft.weightUnit = profile.weightUnit;
      }
      _ready = true;
    });
  }

  List<_Step> get _activeSteps {
    return _ordered.where((step) {
      if (step == _Step.goalDetails && !_draft.needsGoalDetails) {
        return false;
      }
      return true;
    }).toList();
  }

  double get _progress {
    final steps = _activeSteps;
    final index = steps.indexOf(_step);
    if (index < 0) return 0.1;
    return (index + 1) / steps.length;
  }

  void _goNext() {
    final steps = _activeSteps;
    final index = steps.indexOf(_step);
    if (index < 0 || index >= steps.length - 1) return;

    final next = steps[index + 1];
    if (next == _Step.summary) {
      _profile = _builder.build(_draft);
    }
    setState(() => _step = next);
  }

  void _goBack() {
    if (_step == _Step.goalDetails &&
        (_goalDetailsKey.currentState?.tryGoBack() ?? false)) {
      return;
    }

    final steps = _activeSteps;
    final index = steps.indexOf(_step);
    if (index <= 0) return;
    setState(() => _step = steps[index - 1]);
  }

  Future<void> _finish() async {
    final profile = _profile ?? _builder.build(_draft);
    setState(() {
      _loading = true;
      _profile = profile;
    });

    // MVP: keep rule-based profile (Mifflin–St Jeor + heuristics). No OpenAI.
    final result = await _onboarding.saveOnboarding(
      draft: _draft,
      profile: profile,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.welcome:
        return WelcomeStep(onBegin: _goNext);
      case _Step.goals:
        return GoalsStep(draft: _draft, onContinue: _goNext);
      case _Step.goalDetails:
        return GoalDetailsStep(
          key: _goalDetailsKey,
          draft: _draft,
          onContinue: _goNext,
        );
      case _Step.pulse:
        return PulseStep(draft: _draft, onContinue: _goNext);
      case _Step.zodiac:
        return ZodiacStep(draft: _draft, onContinue: _goNext);
      case _Step.habits:
        return HabitsStep(draft: _draft, onContinue: _goNext);
      case _Step.health:
        return HealthStep(draft: _draft, onContinue: _goNext);
      case _Step.food:
        return FoodStep(draft: _draft, onContinue: _goNext);
      case _Step.summary:
        return SummaryStep(
          profile: _profile ?? _builder.build(_draft),
          isLoading: _loading,
          onEnter: _finish,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return OnboardingScaffold(
      progress: _progress,
      showProgress: _step != _Step.welcome,
      onBack: _step == _Step.welcome ? null : _goBack,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: onboardingPageTransition,
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: _body(),
        ),
      ),
    );
  }
}
