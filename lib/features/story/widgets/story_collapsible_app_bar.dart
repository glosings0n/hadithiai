import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class StoryCollapsibleAppBar extends StatelessWidget {
  final double expandedHeight;
  final double collapsedHeight;
  final bool isCollapsed;
  final String title;
  final String imageUrl;
  final VoidCallback onBackTap;

  const StoryCollapsibleAppBar({
    super.key,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.isCollapsed,
    required this.title,
    required this.imageUrl,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8.0),
        child: GestureDetector(
          onTap: onBackTap,
          child: BlobIconWrapper(
            size: 40,
            backgroundColor: AppColors.primary,
            child: const Icon(AppIcons.back, color: AppColors.background),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _StoryHeroImage(imageUrl: imageUrl),
        title: _CollapsedTitle(
          title: title,
          imageUrl: imageUrl,
          isCollapsed: isCollapsed,
        ),
        titlePadding: EdgeInsetsDirectional.only(
          bottom: 16,
          start: isCollapsed ? 50 : 20,
          end: 20,
        ),
      ),
    );
  }
}

class _CollapsedTitle extends StatelessWidget {
  final String title;
  final String imageUrl;
  final bool isCollapsed;

  const _CollapsedTitle({
    required this.title,
    required this.imageUrl,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .max,
      spacing: 8,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: .ellipsis,
            textAlign: .center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: isCollapsed ? AppColors.primary : AppColors.background,
              fontWeight: .bold,
              fontSize: 18,
              shadows: isCollapsed
                  ? null
                  : const [Shadow(blurRadius: 24.0, color: Colors.black54)],
            ),
          ),
        ),
        if (isCollapsed) ...[_StoryThumb(imageUrl: imageUrl)],
      ],
    );
  }
}

class _StoryThumb extends StatelessWidget {
  final String imageUrl;

  const _StoryThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: AppColors.primary.withAlpha(120),
      width: 2,
    );
    final memoryImage = _tryDecodeDataUrl(imageUrl);

    if (imageUrl.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        clipBehavior: .antiAlias,
        decoration: BoxDecoration(shape: .circle, border: border),
        child: Image.asset(AppImages.hero, fit: .cover),
      );
    }

    if (memoryImage != null) {
      return Container(
        width: 32,
        height: 32,
        clipBehavior: .antiAlias,
        decoration: BoxDecoration(shape: .circle, border: border),
        child: Image.memory(
          memoryImage,
          fit: .cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(AppImages.hero, fit: .cover);
          },
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      clipBehavior: .antiAlias,
      decoration: BoxDecoration(shape: .circle, border: border),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: .cover,
        errorWidget: (context, url, error) {
          return Image.asset(AppImages.hero, fit: .cover);
        },
      ),
    );
  }
}

class _StoryHeroImage extends StatelessWidget {
  final String imageUrl;

  const _StoryHeroImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final memoryImage = _tryDecodeDataUrl(imageUrl);

    if (imageUrl.isEmpty) {
      return Image.asset(AppImages.hero, fit: .cover);
    }

    if (memoryImage != null) {
      return Image.memory(
        memoryImage,
        fit: .cover,
        color: AppColors.primary,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(AppImages.hero, fit: .cover);
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: .cover,
      color: AppColors.primary,
      errorWidget: (context, url, error) {
        return Image.asset(AppImages.hero, fit: .cover);
      },
    );
  }
}

Uint8List? _tryDecodeDataUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('data:image')) {
    return null;
  }

  final commaIndex = trimmed.indexOf(',');
  if (commaIndex <= 0 || commaIndex + 1 >= trimmed.length) {
    return null;
  }

  final encoded = trimmed.substring(commaIndex + 1);
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}
