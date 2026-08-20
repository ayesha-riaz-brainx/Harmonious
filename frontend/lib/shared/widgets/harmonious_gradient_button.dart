import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

class HarmoniousGradientButton extends StatelessWidget {
  const HarmoniousGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: enabled
                ? [
                    AppColors.buttonGradientStart,
                    AppColors.buttonGradientEnd,
                  ]
                : [
                    AppColors.buttonGradientStart.withValues(alpha: 0.45),
                    AppColors.buttonGradientEnd.withValues(alpha: 0.45),
                  ],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimaryButton,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
