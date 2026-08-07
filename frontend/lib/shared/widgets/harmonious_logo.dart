import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

class HarmoniousLogo extends StatelessWidget {
  const HarmoniousLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glow,
              boxShadow: [
                BoxShadow(
                  color: AppColors.lavender.withValues(alpha: 0.18),
                  blurRadius: 36,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lavender.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
          ),
          Text(
            '∞',
            style: TextStyle(
              fontSize: size * 0.42,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w300,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
