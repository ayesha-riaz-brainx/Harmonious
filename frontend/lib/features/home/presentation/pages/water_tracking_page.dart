import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/water_glass_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class WaterTrackingPage extends StatefulWidget {
  const WaterTrackingPage({super.key});

  @override
  State<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends State<WaterTrackingPage> {
  final _home = HomeService();
  final _api = FeatureService();

  TodayState? _today;
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _home.fetchToday();
      if (!mounted) return;
      setState(() {
        _today = data.today;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(error);
    }
  }

  Future<void> _addMl(int ml) async {
    final liters = ml / 1000.0;
    setState(() => _busy = true);
    try {
      final result = await _api.post('captures', {
        'type': 'water',
        'payload': {
          'liters': liters,
          'ml': ml,
          'glasses': double.parse((ml / 250).toStringAsFixed(2)),
        },
      });
      TodayState today;
      if (result['home'] is Map) {
        today = HomeDashboard.fromJson(
          Map<String, dynamic>.from(result['home'] as Map),
        ).today;
      } else {
        today = (await _home.fetchToday()).today;
      }
      if (!mounted) return;
      setState(() {
        _today = today;
        _busy = false;
        _changed = true;
      });
      _toast('$ml ml logged');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(error);
    }
  }

  Future<void> _analyze() async {
    final today = _today;
    if (today == null) return;

    // Rule-based hydration tips — no OpenAI.
    final liters = today.waterLiters;
    final goal = today.waterGoal <= 0 ? 2.5 : today.waterGoal;
    final glasses = (liters / 0.25).floor();
    final goalGlasses = (goal / 0.25).round().clamp(4, 16);
    final remaining = (goal - liters).clamp(0.0, goal);
    final pct = ((liters / goal) * 100).round().clamp(0, 999);

    String summary;
    final actions = <String>[];

    if (pct >= 100) {
      summary =
          'Nice work — you\'ve hit your $goalGlasses-glass goal '
          '(${liters.toStringAsFixed(1)} L). Keep sipping lightly through the evening.';
      actions.addAll([
        'Have a small glass with dinner if you feel thirsty',
        'Ease off large drinks close to bedtime for better sleep',
      ]);
    } else if (pct >= 60) {
      summary =
          'You\'re at $glasses of $goalGlasses glasses ($pct%). '
          '${remaining.toStringAsFixed(1)} L left to reach your goal.';
      actions.addAll([
        'Add one more 250 ml glass in the next hour',
        'Pair a glass with your next meal or snack',
      ]);
    } else if (pct >= 25) {
      summary =
          'You\'ve logged $glasses glasses so far ($pct% of goal). '
          'A few steady sips will close the gap.';
      actions.addAll([
        'Set a reminder for mid-afternoon',
        'Log a 250 ml glass now to rebuild momentum',
        'Keep a bottle visible on your desk',
      ]);
    } else {
      summary =
          'Hydration is just getting started ($glasses glasses). '
          'Your goal is about $goalGlasses glasses (${goal.toStringAsFixed(1)} L).';
      actions.addAll([
        'Drink a full glass right now',
        'Aim for one glass every 1–2 waking hours',
        'Start tomorrow with a glass before coffee or tea',
      ]);
    }

    setState(() {
      _analysis = {
        'title': 'Hydration check',
        'summary': summary,
        'actions': actions,
        'source': 'rules',
      };
    });
  }

  void _toast(Object value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: HarmoniousBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Water intake'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context, _changed),
            ),
          ),
          body: _loading || today == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      HarmoniousSpacing.screenHorizontal,
                      8,
                      HarmoniousSpacing.screenHorizontal,
                      32,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      const HarmoniousSectionHeader(
                        title: 'Fill your bottle',
                        subtitle:
                            'Tap a sip size whenever you drink — the bottle fills as you go.',
                      ),
                      const SizedBox(height: 18),
                      WaterGlassCard(
                        liters: today.waterLiters,
                        goalLiters: today.waterGoal,
                        busy: _busy,
                        onAddMl: _addMl,
                      ),
                      const SizedBox(height: 18),
                      HarmoniousGradientButton(
                        label: 'Get hydration tips',
                        onPressed: _analyze,
                      ),
                      if (_analysis != null) ...[
                        const SizedBox(height: 18),
                        HarmoniousCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _analysis!['title']?.toString() ??
                                    'Hydration tips',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _analysis!['summary']?.toString() ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              for (final action
                                  in ((_analysis!['actions'] as List?) ?? []))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $action'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
