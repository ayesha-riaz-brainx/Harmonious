import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

class HarmoniousTextField extends StatelessWidget {
  const HarmoniousTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.textInputAction,
    this.isRequired = false,
    this.enabled = true,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool isRequired;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final trailing = suffix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                obscureText: obscureText,
                validator: validator,
                textInputAction: textInputAction,
                inputFormatters: inputFormatters,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                cursorColor: AppColors.lavender,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: hintText,
                  hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                  errorStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            ...[?trailing],
          ],
        ),
        Container(height: 1, color: AppColors.inputLine),
      ],
    );
  }
}
