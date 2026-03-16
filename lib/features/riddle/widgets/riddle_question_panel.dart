import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class RiddleQuestionPanel extends StatelessWidget {
  final RiddleLoadState state;
  final String? question;
  final String statusMessage;
  final String? errorMessage;
  final VoidCallback onRetry;

  const RiddleQuestionPanel({
    super.key,
    required this.state,
    required this.question,
    required this.statusMessage,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: .start,
          spacing: 8,
          children: [
            Text(
              'Family Riddle Time',
              style: context.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (state == RiddleLoadState.loading)
              Row(
                spacing: 12,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  Expanded(
                    child: Text(
                      'Loading the next challenge...',
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            else if (state == RiddleLoadState.error)
              Column(
                crossAxisAlignment: .start,
                spacing: 12,
                children: [
                  Text(
                    errorMessage ?? 'Could not load challenge.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(
                      AppIcons.refresh,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Retry',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              )
            else
              Text(
                question ?? 'No challenge available.',
                style: context.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            Text(
              statusMessage,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
