import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class VisionPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isVisible;
  final bool isAiSeeing;

  const VisionPreviewWidget({
    super.key,
    required this.controller,
    required this.isVisible,
    required this.isAiSeeing,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || controller == null || !controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isAiSeeing ? AppColors.primary : AppColors.secondary,
          width: isAiSeeing ? 3 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAiSeeing ? AppColors.primary : AppColors.secondary)
                .withAlpha(isAiSeeing ? 120 : 70),
            blurRadius: isAiSeeing ? 14 : 8,
            spreadRadius: isAiSeeing ? 2 : 0,
          ),
        ],
      ),
      child: ClipOval(child: CameraPreview(controller!)),
    );
  }
}
