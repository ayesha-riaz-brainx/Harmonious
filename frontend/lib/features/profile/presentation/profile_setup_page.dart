import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/services/profile_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/auth_screen_scaffold.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_text_field.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _profiles = ProfileService();

  String _gender = 'Prefer not to say';
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save({required bool markCompleted, bool validate = true}) async {
    if (validate && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final displayName = _displayNameController.text.trim().isEmpty
        ? 'Friend'
        : _displayNameController.text.trim();

    final result = await _profiles.saveProfileSetup(
      displayName: displayName,
      age: age,
      gender: _gender,
      height: height,
      weight: weight,
      country: _countryController.text.trim(),
      weightUnit: _weightUnit,
      heightUnit: _heightUnit,
      markCompleted: markCompleted,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.onboarding,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      showBack: true,
      onBack: () async {
        // Leave setup → sign out to welcome so they aren't stuck.
        await AuthService().logout();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: AppStrings.profileSetupTitle,
            subtitle: AppStrings.profileSetupSubtitle,
          ),
          const SizedBox(height: 20),
          AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HarmoniousTextField(
                    label: AppStrings.displayNameLabel,
                    controller: _displayNameController,
                    hintText: AppStrings.displayNameHint,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  HarmoniousTextField(
                    label: AppStrings.ageLabel,
                    controller: _ageController,
                    hintText: AppStrings.ageHint,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      final age = int.tryParse(value.trim());
                      if (age == null || age < 1 || age > 120) {
                        return 'Enter a valid age.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.labelSmall,
                        children: const [
                          TextSpan(text: AppStrings.genderLabel),
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    items: const [
                      'Female',
                      'Male',
                      'Non-binary',
                      'Prefer not to say',
                    ]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _gender = value);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  HarmoniousTextField(
                    label: AppStrings.heightLabel,
                    controller: _heightController,
                    hintText: _heightUnit == 'cm' ? '170' : '5.7',
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter a valid height.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  HarmoniousTextField(
                    label: AppStrings.weightLabel,
                    controller: _weightController,
                    hintText: _weightUnit == 'kg' ? '65' : '143',
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Enter a valid weight.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  HarmoniousTextField(
                    label: AppStrings.countryLabel,
                    controller: _countryController,
                    hintText: AppStrings.countryHint,
                    isRequired: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.unitsLabel,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _UnitChip(
                          label: 'kg / cm',
                          selected: _weightUnit == 'kg',
                          onTap: () {
                            setState(() {
                              _weightUnit = 'kg';
                              _heightUnit = 'cm';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _UnitChip(
                          label: 'lb / ft',
                          selected: _weightUnit == 'lb',
                          onTap: () {
                            setState(() {
                              _weightUnit = 'lb';
                              _heightUnit = 'ft';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  HarmoniousGradientButton(
                    label: AppStrings.continueLabel,
                    isLoading: _isLoading,
                    onPressed: () => _save(markCompleted: true),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => _save(markCompleted: true, validate: false),
                    child: const Text(
                      AppStrings.skip,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.primaryBright : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
