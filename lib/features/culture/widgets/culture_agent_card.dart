import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class CultureAgentCard extends StatelessWidget {
  final String title;
  final String summary;
  final String region;

  const CultureAgentCard({
    super.key,
    required this.title,
    required this.summary,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      onTap: () {},
      child: Padding(
        padding: const .all(16),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.shieldCheck, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Grounding Agent (Culture)',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: .w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Every story is checked and enriched before narration to reduce hallucinations and preserve authentic cultural references.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            _Bullet(
              text: 'Uses curated prompts and folklore exemplars by region.',
            ),
            _Bullet(
              text:
                  'Injects proverbs, context clues, and safe child-friendly references.',
            ),
            _Bullet(
              text:
                  'Supports language strategy adaptation at app entry/session creation.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const .symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: .circular(12),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Text(
                'Today: $title • $region\n${summary.isEmpty ? 'Waiting for generated cultural summary...' : summary}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: .bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(bottom: 6),
      child: Row(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(AppIcons.circle, size: 8, color: AppColors.secondary),
          ),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
