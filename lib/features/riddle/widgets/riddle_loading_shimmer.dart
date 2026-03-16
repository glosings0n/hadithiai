import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:shimmer/shimmer.dart';

class RiddleLoadingShimmer extends StatelessWidget {
  const RiddleLoadingShimmer({super.key});

  static const List<Color> _gridColors = <Color>[
    Color(0xFFEFAE58),
    Color(0xFF89A7E0),
    Color(0xFF8BC37A),
    Color(0xFFD18AC5),
  ];

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.secondary.withAlpha(50),
      highlightColor: AppColors.primary.withAlpha(150),
      period: const Duration(seconds: 2),
      child: Column(
        children: [
          _questionPanelSkeleton(),
          const SizedBox(height: 16),
          Expanded(child: _gridSkeleton()),
        ],
      ),
    );
  }

  Widget _questionPanelSkeleton() {
    return GlassmorphicCard(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(
              width: 170,
              height: 22,
              color: AppColors.primary.withAlpha(170),
            ),
            const SizedBox(height: 14),
            _line(width: double.infinity, height: 18),
            const SizedBox(height: 10),
            _line(width: double.infinity, height: 18),
            const SizedBox(height: 10),
            _line(width: 220, height: 18),
            const SizedBox(height: 16),
            _line(
              width: double.infinity,
              height: 12,
              color: AppColors.textSecondary.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridSkeleton() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final color = _gridColors[index % _gridColors.length];
        return Container(
          decoration: BoxDecoration(
            color: _darken(color, 0.10),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _darken(color, 0.05), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Spacer(),
                        _line(
                          width: double.infinity,
                          height: 14,
                          color: AppColors.background.withAlpha(210),
                        ),
                        const SizedBox(height: 8),
                        _line(
                          width: 90,
                          height: 14,
                          color: AppColors.background.withAlpha(210),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _line({
    required double width,
    required double height,
    Color color = const Color(0xFFD9CFC6),
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
