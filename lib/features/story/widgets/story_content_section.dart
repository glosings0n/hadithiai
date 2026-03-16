import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hadithi_ai/core/core.dart';

import 'read_to_me_toggle.dart';

class StoryContentSection extends StatelessWidget {
  final String title;
  final String content;

  const StoryContentSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          ReadToMeToggle(storyTitle: title, storyContent: content),
          MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              p: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.6,
              ),
              strong: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
              h1: context.textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontFamily: 'Fredoka',
              ),
              h2: context.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontFamily: 'Fredoka',
              ),
              blockquote: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              listBullet: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
