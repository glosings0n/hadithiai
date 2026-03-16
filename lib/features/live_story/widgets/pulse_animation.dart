import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class PulseAnimation extends StatefulWidget {
  final double audioLevel;
  final bool isAiSpeaking;
  final bool isUserSpeaking;

  const PulseAnimation({
    super.key,
    required this.audioLevel,
    this.isAiSpeaking = false,
    this.isUserSpeaking = false,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  bool get _isActive =>
      widget.isAiSpeaking || widget.isUserSpeaking || widget.audioLevel > 0.01;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    if (_isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    if (!_isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveLevel = widget.audioLevel.clamp(0.0, 1.0);
    final bool aiActive = widget.isAiSpeaking;
    final bool userActive = widget.isUserSpeaking && !aiActive;
    final Color baseColor = aiActive
        ? AppColors.success
        : userActive
        ? AppColors.primary
        : AppColors.textSecondary;
    final String speakerLabel = aiActive
        ? 'AI'
        : userActive
        ? 'YOU'
        : 'IDLE';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double curvedValue = _isActive ? _curve.value : 0;
        final double waveStrength = aiActive
            ? 1.7
            : userActive
            ? 1.35
            : 0.55;
        const double baseSize = 88.0;
        final double audioDrivenSize =
            (130.0 + (80.0 * waveStrength)) * effectiveLevel;
        final double radius =
            baseSize + (audioDrivenSize * (0.55 + (curvedValue * 0.45)));

        final double middleRadius = radius * 0.72;
        final double coreRadius = radius * 0.48;
        final double auraOpacity = _isActive ? (aiActive ? 0.45 : 0.3) : 0.12;
        final double coreScale = 0.94 + (curvedValue * 0.14);

        return SizedBox(
          width: 320,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: PulsePainter(
                  radius: radius,
                  intensity: effectiveLevel,
                  glowColor: baseColor.withAlpha((255 * auraOpacity).round()),
                ),
                child: const SizedBox(width: 300, height: 300),
              ),
              CustomPaint(
                painter: PulsePainter(
                  radius: middleRadius,
                  intensity: (effectiveLevel * 0.9).clamp(0.05, 1.0),
                  glowColor: baseColor.withAlpha(140),
                ),
                child: const SizedBox(width: 320, height: 320),
              ),
              Transform.scale(
                scale: coreScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: coreRadius,
                  height: coreRadius,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.background.withAlpha(aiActive ? 245 : 225),
                        baseColor.withAlpha(aiActive ? 225 : 185),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withAlpha(aiActive ? 210 : 140),
                        blurRadius: aiActive ? 32 : 20,
                        spreadRadius: aiActive ? 8 : 3,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    speakerLabel,
                    style: TextStyle(
                      color: baseColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: aiActive ? 14 : 12,
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
}

class PulsePainter extends CustomPainter {
  final double radius;
  final double intensity;
  final Color glowColor;

  PulsePainter({
    required this.radius,
    required this.intensity,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final double clampedIntensity = intensity.clamp(0.05, 1.0);

    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withAlpha((255 * 0.3 * clampedIntensity).round())
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.5);
    canvas.drawCircle(center, radius, glowPaint);

    // Inner, more solid circle
    final corePaint = Paint()
      ..color = glowColor.withAlpha((255 * 0.8 * clampedIntensity).round())
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.1);
    canvas.drawCircle(center, radius * 0.6, corePaint);
  }

  @override
  bool shouldRepaint(covariant PulsePainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.intensity != intensity;
  }
}
