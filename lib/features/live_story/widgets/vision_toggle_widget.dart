import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class VisionToggleWidget extends StatelessWidget {
  final bool value;
  final String status;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  const VisionToggleWidget({
    super.key,
    required this.value,
    required this.status,
    this.isBusy = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary.withAlpha(36)
                    : AppColors.secondary.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: Icon(
                value ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                color: value ? AppColors.primary : AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode Vision',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            if (isBusy) const SizedBox(width: 12),
            CupertinoSwitch(
              activeTrackColor: AppColors.primary,
              value: value,
              onChanged: isBusy ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
