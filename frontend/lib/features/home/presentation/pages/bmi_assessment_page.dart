import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

/// WHO adult BMI categories (kg/m²).
enum BmiCategory {
  underweight,
  normal,
  overweight,
  obese,
}

class BmiResult {
  const BmiResult({
    required this.bmi,
    required this.category,
    required this.label,
    required this.explanation,
    required this.healthyMinKg,
    required this.healthyMaxKg,
  });

  final double bmi;
  final BmiCategory category;
  final String label;
  final String explanation;
  final double healthyMinKg;
  final double healthyMaxKg;
}

BmiResult calculateBmi({
  required double heightCm,
  required double weightKg,
}) {
  final heightM = heightCm / 100.0;
  final bmi = weightKg / (heightM * heightM);
  final healthyMin = 18.5 * heightM * heightM;
  final healthyMax = 24.9 * heightM * heightM;

  late final BmiCategory category;
  late final String label;
  late final String explanation;

  if (bmi < 18.5) {
    category = BmiCategory.underweight;
    label = 'Underweight';
    explanation =
        'Your BMI is below the WHO adult range for a healthy weight. '
        'Focus on nutrient-dense meals and talk with a clinician if weight '
        'loss was unintentional.';
  } else if (bmi < 25) {
    category = BmiCategory.normal;
    label = 'Normal weight';
    explanation =
        'Your BMI is in the WHO adult healthy-weight range. Keep up balanced '
        'eating, movement, sleep, and hydration.';
  } else if (bmi < 30) {
    category = BmiCategory.overweight;
    label = 'Overweight';
    explanation =
        'Your BMI is above the WHO adult healthy-weight range. Small, steady '
        'habits around food and activity often help more than crash diets.';
  } else {
    category = BmiCategory.obese;
    label = 'Obese';
    explanation =
        'Your BMI is in the WHO adult obesity range. Consider gradual lifestyle '
        'changes and professional guidance for a plan that fits your health.';
  }

  return BmiResult(
    bmi: bmi,
    category: category,
    label: label,
    explanation: explanation,
    healthyMinKg: healthyMin,
    healthyMaxKg: healthyMax,
  );
}

class BmiAssessmentPage extends StatefulWidget {
  const BmiAssessmentPage({super.key});

  @override
  State<BmiAssessmentPage> createState() => _BmiAssessmentPageState();
}

class _BmiAssessmentPageState extends State<BmiAssessmentPage> {
  final _api = FeatureService();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  String _gender = 'prefer_not_to_say';
  bool _loading = true;
  BmiResult? _result;

  static const _genders = [
    ('female', 'Female'),
    ('male', 'Male'),
    ('non_binary', 'Non-binary'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    try {
      final data = await _api.get('settings');
      final profile =
          Map<String, dynamic>.from(data['profile'] as Map? ?? {});
      final onboarding =
          Map<String, dynamic>.from(data['onboarding_data'] as Map? ?? {});
      if (!mounted) return;

      num? numOf(String key) {
        final direct = profile[key];
        if (direct is num) return direct;
        final parsed = num.tryParse(direct?.toString() ?? '');
        if (parsed != null) return parsed;
        final nested = onboarding[key];
        if (nested is num) return nested;
        return num.tryParse(nested?.toString() ?? '');
      }

      final age = numOf('age');
      final height = numOf('height');
      final weight = numOf('weight');
      final gender = (profile['gender'] ?? onboarding['gender'])
          ?.toString()
          .toLowerCase()
          .trim();
      final heightUnit =
          (profile['height_unit'] ?? onboarding['height_unit'])
              ?.toString()
              .toLowerCase();
      final weightUnit =
          (profile['weight_unit'] ?? onboarding['weight_unit'])
              ?.toString()
              .toLowerCase();

      double? heightCm;
      if (height != null) {
        heightCm = heightUnit == 'ft'
            ? height.toDouble() * 30.48
            : height.toDouble();
      }

      double? weightKg;
      if (weight != null) {
        weightKg = weightUnit == 'lb'
            ? weight.toDouble() * 0.453592
            : weight.toDouble();
      }

      setState(() {
        if (age != null) _age.text = age.round().toString();
        if (heightCm != null) {
          _height.text = heightCm.toStringAsFixed(
            heightCm == heightCm.roundToDouble() ? 0 : 1,
          );
        }
        if (weightKg != null) {
          _weight.text = weightKg.toStringAsFixed(
            weightKg == weightKg.roundToDouble() ? 0 : 1,
          );
        }
        if (gender != null && gender.isNotEmpty) {
          final match = _genders.where((g) => g.$1 == gender);
          if (match.isNotEmpty) {
            _gender = gender;
          } else if (gender.startsWith('f')) {
            _gender = 'female';
          } else if (gender.startsWith('m')) {
            _gender = 'male';
          }
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _calculate() async {
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());

    if (age == null || age < 18 || age > 120) {
      _toast('Enter a valid adult age (18+). BMI categories here are for adults.');
      return;
    }
    if (height == null || height < 100 || height > 250) {
      _toast('Enter height in cm (100–250).');
      return;
    }
    if (weight == null || weight < 30 || weight > 300) {
      _toast('Enter weight in kg (30–300).');
      return;
    }

    setState(() {
      _result = calculateBmi(heightCm: height, weightKg: weight);
    });

    // Persist so You / profile stay in sync with onboarding values.
    try {
      await _api.patch('settings', {
        'profile': {
          'age': age,
          'height': height,
          'weight': weight,
          'gender': _gender,
          'height_unit': 'cm',
          'weight_unit': 'kg',
        },
      });
    } catch (_) {
      // BMI result still shows even if save fails.
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _categoryColor(BmiCategory category) {
    return switch (category) {
      BmiCategory.underweight => AppColors.sky,
      BmiCategory.normal => AppColors.mint,
      BmiCategory.overweight => AppColors.amber,
      BmiCategory.obese => AppColors.coral,
    };
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('BMI assessment'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  HarmoniousSpacing.screenHorizontal,
                  8,
                  HarmoniousSpacing.screenHorizontal,
                  36,
                ),
                children: [
                  const HarmoniousSectionHeader(
                    title: 'Weight & BMI',
                  ),
                  const SizedBox(height: 22),
                  _field(_age, 'Age', 'years'),
                  const SizedBox(height: 14),
                  const Text(
                    'Gender',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _genders)
                        ChoiceChip(
                          label: Text(item.$2),
                          selected: _gender == item.$1,
                          onSelected: (_) => setState(() => _gender = item.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(_height, 'Height', 'cm'),
                  const SizedBox(height: 14),
                  _field(_weight, 'Weight', 'kg'),
                  const SizedBox(height: 22),
                  HarmoniousGradientButton(
                    label: 'Calculate BMI',
                    onPressed: _calculate,
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _ResultCard(
                      result: _result!,
                      color: _categoryColor(_result!.category),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String suffix,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.color});

  final BmiResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HarmoniousCard(
      accentColor: color,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.bmi.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.explanation,
            style: const TextStyle(
              height: 1.5,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Healthy weight range for your height: '
            '${result.healthyMinKg.toStringAsFixed(0)}–'
            '${result.healthyMaxKg.toStringAsFixed(0)} kg '
            '(BMI 18.5–24.9).',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Categories: Underweight <18.5 · Normal 18.5–24.9 · '
            'Overweight 25–29.9 · Obese ≥30.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
