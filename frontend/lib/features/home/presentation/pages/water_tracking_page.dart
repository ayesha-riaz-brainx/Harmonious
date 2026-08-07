import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/water_glass_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';

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
  bool _analyzing = false;
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
    setState(() => _analyzing = true);
    try {
      final data = await _api.post('ai/tool', {
        'tool': 'water_intake',
        'input': {},
      });
      if (!mounted) return;
      setState(() {
        _analysis = Map<String, dynamic>.from(data['result'] as Map? ?? {});
        _analyzing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      _toast(error);
    }
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    const Text(
                      'Fill your bottle',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a sip size whenever you drink — the bottle fills as you go.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),
                    WaterGlassCard(
                      liters: today.waterLiters,
                      goalLiters: today.waterGoal,
                      busy: _busy,
                      onAddMl: _addMl,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _analyzing ? null : _analyze,
                      icon: _analyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _analyzing ? 'Analyzing…' : 'Get AI hydration analysis',
                      ),
                    ),
                    if (_analysis != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _analysis!['title']?.toString() ?? 'AI Analysis',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _analysis!['summary']?.toString() ?? '',
                              style: const TextStyle(height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            for (final action in ((_analysis!['actions']
                                    as List?) ??
                                []))
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
    );
  }
}
