import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class StorySignatureFooter extends StatelessWidget {
  final String signature;

  const StorySignatureFooter({super.key, required this.signature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 24, bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          Expanded(
            child: Divider(
              color: AppColors.primary.withAlpha(140),
              thickness: 1.2,
              endIndent: 12,
            ),
          ),
          Flexible(
            child: Text(
              signature,
              textAlign: TextAlign.end,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
