import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/styles/app_colors.dart';

class MainGridCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const MainGridCard({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.label = "",
    this.iconSize = 60,
    this.iconColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Compute derived shades for the 3D effect.
    final hsl = HSLColor.fromColor(backgroundColor);

    // Bottom shadow (darker).
    final bottomShadowColor = hsl
        .withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0))
        .toColor();

    // Inner shadow/border (slightly darker).
    final innerBorderColor = hsl
        .withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0))
        .toColor();

    // Watermark shade (slightly darker than the base color).
    final watermarkColor = hsl
        .withLightness((hsl.lightness - 0.03).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bottomShadowColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: innerBorderColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    alignment: AlignmentGeometry.center,
                    children: [
                      // --- 3. Background icon watermark ---
                      Positioned(
                        bottom: -30,
                        right: -30,
                        child: Icon(icon, size: 150, color: watermarkColor),
                      ),

                      // --- 4. Main content ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: .center,
                          children: [
                            Expanded(
                              child: Center(
                                child: Icon(
                                  icon,
                                  size: iconSize,
                                  color: iconColor ?? AppColors.textPrimary,
                                ),
                              ),
                            ),

                            // Bottom label.
                            if (label.isNotEmpty)
                              Text(
                                label.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: .bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
