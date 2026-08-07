import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_text_field.dart';

class AboutYouStep extends StatefulWidget {
  const AboutYouStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<AboutYouStep> createState() => _AboutYouStepState();
}

class _AboutYouStepState extends State<AboutYouStep> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _age = TextEditingController(
      text: widget.draft.age?.toString() ?? '',
    );
    _height = TextEditingController(
      text: widget.draft.height?.toString() ?? '',
    );
    _weight = TextEditingController(
      text: widget.draft.weight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = widget.draft.birthday ??
        DateTime(now.year - (widget.draft.age ?? 25));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.lavender,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      widget.draft.birthday = picked;
      widget.draft.age = now.year -
          picked.year -
          ((now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day))
              ? 1
              : 0);
      _age.text = widget.draft.age.toString();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (widget.draft.gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }
    if (widget.draft.activityLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your activity level.')),
      );
      return;
    }

    widget.draft.age = int.tryParse(_age.text.trim());
    widget.draft.height = double.tryParse(_height.text.trim());
    widget.draft.weight = double.tryParse(_weight.text.trim());
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingStepHeader(
            eyebrow: 'About you',
            title: 'Tell me a little about yourself',
            subtitle:
                'This helps me size recommendations to your body and lifestyle.',
          ),
          const SizedBox(height: 8),
          OnboardingFieldLabel('Birthday'),
          InkWell(
            onTap: _pickBirthday,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.inputLine)),
              ),
              child: Text(
                draft.birthday == null
                    ? 'Select date'
                    : '${draft.birthday!.day}/${draft.birthday!.month}/${draft.birthday!.year}',
                style: TextStyle(
                  color: draft.birthday == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          HarmoniousTextField(
            label: 'AGE',
            controller: _age,
            isRequired: true,
            keyboardType: TextInputType.number,
            hintText: '28',
            validator: (v) {
              final age = int.tryParse(v?.trim() ?? '');
              if (age == null || age < 10 || age > 100) {
                return 'Enter a valid age.';
              }
              return null;
            },
          ),
          OnboardingFieldLabel('Gender', required: true),
          OnboardingChipWrap(
            options: OnboardingOptions.genders,
            selected: {
              if (draft.gender != null) draft.gender!,
            },
            multi: false,
            onToggle: (value) {
              setState(() => draft.gender = value);
            },
          ),
          const SizedBox(height: 8),
          HarmoniousTextField(
            label: 'HEIGHT (${draft.heightUnit})',
            controller: _height,
            isRequired: true,
            keyboardType: TextInputType.number,
            hintText: draft.heightUnit == 'cm' ? '170' : '5.7',
            validator: (v) =>
                double.tryParse(v?.trim() ?? '') == null
                    ? 'Enter height.'
                    : null,
          ),
          const SizedBox(height: 8),
          HarmoniousTextField(
            label: 'WEIGHT (${draft.weightUnit})',
            controller: _weight,
            isRequired: true,
            keyboardType: TextInputType.number,
            hintText: draft.weightUnit == 'kg' ? '65' : '143',
            validator: (v) =>
                double.tryParse(v?.trim() ?? '') == null
                    ? 'Enter weight.'
                    : null,
          ),
          OnboardingFieldLabel('Activity level', required: true),
          OnboardingChipWrap(
            options: OnboardingOptions.activityLevels,
            selected: {
              if (draft.activityLevel != null) draft.activityLevel!,
            },
            multi: false,
            onToggle: (value) => setState(() => draft.activityLevel = value),
          ),
          OnboardingFooterButton(label: 'Continue', onPressed: _submit),
        ],
      ),
    );
  }
}
