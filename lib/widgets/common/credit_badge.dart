import 'package:flutter/material.dart';
import 'package:chatrizz/app/theme/app_colors.dart';

class CreditBadge extends StatelessWidget {
  final int credits;
  final VoidCallback? onTap;

  const CreditBadge({super.key, required this.credits, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.purpleSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.purpleLight),
              const SizedBox(width: 4),
              Text(
                '$credits',
                style: const TextStyle(
                  color: AppColors.purpleLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
