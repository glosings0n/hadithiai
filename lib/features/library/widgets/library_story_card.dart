import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class LibraryStoryCard extends StatelessWidget {
  final StoryModel story;

  const LibraryStoryCard({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(215),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withAlpha(16),
            offset: const Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .end,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: .start,
            spacing: 12,
            children: [
              _DateCard(day: story.day, month: story.month),
              Expanded(child: _StoryInfo(story: story)),
            ],
          ),
          _RegionLabel(region: story.region),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final int day;
  final String month;

  const _DateCard({required this.day, required this.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            '$day',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFamily: 'Hanalei',
              color: AppColors.primary,
              fontSize: 34,
            ),
          ),
          Text(
            month,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: .bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryInfo extends StatelessWidget {
  final StoryModel story;

  const _StoryInfo({required this.story});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          story.title,
          maxLines: 2,
          overflow: .ellipsis,
          style: context.textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: .bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          story.summary,
          maxLines: 3,
          overflow: .ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RegionLabel extends StatelessWidget {
  final String region;

  const _RegionLabel({required this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(36),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: .min,
        spacing: 6,
        children: [
          Icon(Icons.public_rounded, size: 14, color: AppColors.secondary),
          Text(
            region,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.secondary,
              fontWeight: .w700,
            ),
          ),
        ],
      ),
    );
  }
}
