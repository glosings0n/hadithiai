import 'package:flutter/cupertino.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:provider/provider.dart';

class ReadToMeToggle extends StatelessWidget {
  final String storyTitle;
  final String storyContent;

  const ReadToMeToggle({
    super.key,
    required this.storyTitle,
    required this.storyContent,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryNarrationProvider>(
      builder: (context, audioProvider, child) {
        return Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              'Read to me',
              style: context.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Fredoka',
                fontWeight: .w600,
                fontSize: 22,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: audioProvider.isBusy
                  ? _NarrationLoadingState(
                      key: const ValueKey('narration-loading'),
                      label: audioProvider.isStarting
                          ? 'Starting...'
                          : 'Stopping...',
                    )
                  : CupertinoSwitch(
                      key: const ValueKey('narration-switch'),
                      activeTrackColor: AppColors.primary,
                      value: audioProvider.isReading,
                      onChanged: (bool value) {
                        if (value) {
                          audioProvider.startReading(
                            title: storyTitle,
                            content: storyContent,
                          );
                        } else {
                          audioProvider.stopReading();
                        }
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NarrationLoadingState extends StatelessWidget {
  final String label;

  const _NarrationLoadingState({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CupertinoActivityIndicator(radius: 8),
        const SizedBox(width: 8),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
