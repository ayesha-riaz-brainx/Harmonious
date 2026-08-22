import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

enum AuthNoticeTone { success, error, info, warning }

/// Branded floating snackbars for auth and account flows.
class AuthNotice {
  const AuthNotice._();

  static void show(
    BuildContext context, {
    required String message,
    AuthNoticeTone tone = AuthNoticeTone.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final Color accent;
    final IconData icon;
    switch (tone) {
      case AuthNoticeTone.success:
        accent = AppColors.mint;
        icon = Icons.check_circle_rounded;
        break;
      case AuthNoticeTone.error:
        accent = AppColors.coral;
        icon = Icons.error_outline_rounded;
        break;
      case AuthNoticeTone.warning:
        accent = AppColors.amber;
        icon = Icons.mark_email_unread_outlined;
        break;
      case AuthNoticeTone.info:
        accent = AppColors.primary;
        icon = Icons.info_outline_rounded;
        break;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: accent.withValues(alpha: 0.45)),
          ),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
