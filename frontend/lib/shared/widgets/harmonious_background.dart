import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

class HarmoniousBackground extends StatelessWidget {
  const HarmoniousBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundTop,
            AppColors.background,
            AppColors.background,
          ],
        ),
      ),
      child: child,
    );
  }
}
