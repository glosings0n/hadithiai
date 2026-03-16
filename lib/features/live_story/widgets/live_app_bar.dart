import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class LiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isVisionEnabled;
  final bool isVisionBusy;
  final VoidCallback? onVisionToggle;

  const LiveAppBar({
    super.key,
    this.isVisionEnabled = false,
    this.isVisionBusy = false,
    this.onVisionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: BlobIconWrapper(
            size: 40,
            backgroundColor: AppColors.primary,
            child: const Icon(AppIcons.close, color: AppColors.background),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isVisionBusy ? null : onVisionToggle,
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isVisionEnabled
                      ? AppColors.primary.withAlpha(230)
                      : AppColors.background.withAlpha(190),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isVisionEnabled
                        ? AppColors.background.withAlpha(180)
                        : AppColors.primary.withAlpha(120),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isVisionEnabled
                                  ? AppColors.primary
                                  : AppColors.textPrimary)
                              .withAlpha(20),
                      blurRadius: isVisionEnabled ? 12 : 6,
                      spreadRadius: isVisionEnabled ? 1 : 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVisionBusy)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isVisionEnabled
                                ? AppColors.background
                                : AppColors.primary,
                          ),
                        ),
                      )
                    else
                      Icon(
                        isVisionEnabled
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        size: 18,
                        color: isVisionEnabled
                            ? AppColors.background
                            : AppColors.primary,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      isVisionEnabled ? 'Camera ON' : 'Camera OFF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isVisionEnabled
                            ? AppColors.background
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AgentAvatar extends StatelessWidget {
  final String label;
  final IconData icon;

  const AgentAvatar({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppPillChip(
      icon: icon,
      label: label,
      foregroundColor: AppColors.primary,
      backgroundColor: AppColors.background.withAlpha(51),
      borderColor: AppColors.primary.withAlpha(70),
      iconSize: 18,
      textStyle: const TextStyle(
        color: AppColors.primary,
        fontFamily: 'Fredoka',
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      borderRadius: AppRadii.md,
    );
  }
}
