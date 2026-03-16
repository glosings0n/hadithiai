import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/features.dart';

class HeroSection extends StatelessWidget {
  final StoryModel storyOfTheDay;

  const HeroSection({super.key, this.storyOfTheDay = StoryModel.empty});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            Positioned.fill(child: _buildHeroImage()),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    'Story of the Day',
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: AppColors.background,
                      shadows: [
                        const Shadow(blurRadius: 10.0, color: Colors.black54),
                      ],
                    ),
                  ),
                  Text(
                    storyOfTheDay.title,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.background,
                      fontWeight: .bold,
                      shadows: [
                        Shadow(blurRadius: 20.0, color: Colors.black54),
                      ],
                    ),
                    overflow: .ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  if (storyOfTheDay.isEmpty) {
                    UIHelpers.showSnackBar(
                      context,
                      message: "Still generating the day's story.",
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => StoryScreen(story: storyOfTheDay),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                child: const Icon(AppIcons.play, color: AppColors.background),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (storyOfTheDay.imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(128),
          image: const DecorationImage(
            image: AssetImage(AppImages.hero),
            fit: .cover,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: storyOfTheDay.imageUrl,
      fit: .cover,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(128),
          image: DecorationImage(image: imageProvider, fit: .cover),
        ),
      ),
      placeholder: (context, url) => Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(128),
          image: const DecorationImage(
            image: AssetImage(AppImages.hero),
            fit: .cover,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(128),
          image: const DecorationImage(
            image: AssetImage(AppImages.hero),
            fit: .cover,
          ),
        ),
      ),
    );
  }
}
