import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class CultureRegionsSection extends StatelessWidget {
  final List<StoryModel> stories;

  const CultureRegionsSection({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<StoryModel>>{};
    for (final story in stories) {
      grouped.putIfAbsent(story.region, () => <StoryModel>[]).add(story);
    }

    final regions = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          'Regions and Story Foundations',
          style: context.textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: .bold,
          ),
        ),
        const SizedBox(height: 10),
        ...regions.map((region) {
          final list = grouped[region]!;
          final sampleTitles = list.take(2).map((e) => e.title).join(' • ');
          return Padding(
            padding: const .only(bottom: 10),
            child: GlassmorphicCard(
              onTap: () {},
              child: Padding(
                padding: const .all(14),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.public_rounded,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            region,
                            style: context.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: .w700,
                            ),
                          ),
                        ),
                        Text(
                          '${list.length} seeds',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      list.first.summary,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Examples: $sampleTitles',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: .w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
