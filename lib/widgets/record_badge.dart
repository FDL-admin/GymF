import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

class RecordBadge extends StatelessWidget {
  const RecordBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: const Text(
        'RECORD',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}