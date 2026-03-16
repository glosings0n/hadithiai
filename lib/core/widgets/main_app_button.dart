import 'package:flutter/material.dart';

class MainAppButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  final double width;
  final double height;

  const MainAppButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
    this.width = 200,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final Color darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height + 6,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: darkColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: .bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
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
