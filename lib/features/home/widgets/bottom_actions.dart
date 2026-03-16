import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/features.dart';

class BottomActions extends StatelessWidget {
  const BottomActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.sizeOfHeight * 0.15,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {},
            child: BlobIconWrapper(
              size: 50,
              backgroundColor: AppColors.primary,
              child: const Icon(
                AppIcons.home,
                color: AppColors.background,
                size: 20,
              ),
            ),
          ),
          MainGridCard(
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => const LiveStoryScreen()),
              );
            },
            height: 80,
            width: 80,
            iconSize: 30,
            icon: AppIcons.mic,
            iconColor: AppColors.background,
            backgroundColor: AppColors.secondary,
          ),
          GestureDetector(
            onTap: () {},
            child: BlobIconWrapper(
              size: 50,
              backgroundColor: AppColors.secondary.withAlpha(200),
              child: const Icon(
                AppIcons.library,
                color: AppColors.background,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
