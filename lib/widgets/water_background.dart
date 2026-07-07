import 'dart:math';
import 'package:flutter/material.dart';

/// Animated water background with flowing waves and fish silhouettes.
/// Use as a Stack background behind your content.
class WaterBackground extends StatefulWidget {
  final Widget? child;
  final bool showFish;
  final double waveHeight;
  final Color waterTop;
  final Color waterBottom;

  const WaterBackground({
    super.key,
    this.child,
    this.showFish = true,
    this.waveHeight = 60,
    this.waterTop = const Color(0xFF0A1628),
    this.waterBottom = const Color(0xFF0D2137),
  });

  @override
  State<WaterBackground> createState() => _WaterBackgroundState();
}

class _WaterBackgroundState extends State<WaterBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Water gradient background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (ctx, _) => CustomPaint(
              painter: _WaterPainter(
                waveHeight: widget.waveHeight,
                waterTop: widget.waterTop,
                waterBottom: widget.waterBottom,
                progress: _controller.value,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        // Fish silhouettes
        if (widget.showFish) ...[
          _FishAnimation(
            controller: _controller,
            fishCount: 3,
            opacity: 0.15,
          ),
        ],
        // Content on top
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

/// Paints animated water waves.
class _WaterPainter extends CustomPainter {
  final double waveHeight;
  final Color waterTop;
  final Color waterBottom;
  final double progress;

  _WaterPainter({
    required this.waveHeight,
    required this.waterTop,
    required this.waterBottom,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [waterTop, waterBottom],
    );
    final paint = Paint()..shader = gradient.createShader(rect);

    // Draw waves
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final wave1 = sin((x / size.width * 4 * pi) + (progress * 2 * pi)) * waveHeight;
      final wave2 = sin((x / size.width * 6 * pi) + (progress * 3 * pi + 1)) * (waveHeight * 0.5);
      final wave3 = sin((x / size.width * 2 * pi) + (progress * 1.5 * pi + 2)) * (waveHeight * 0.3);
      final y = size.height - 60 + wave1 + wave2 + wave3;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaterPainter old) => old.progress != progress;
}

/// Animated fish silhouettes swimming across the screen.
class _FishAnimation extends StatelessWidget {
  final AnimationController controller;
  final int fishCount;
  final double opacity;

  const _FishAnimation({
    required this.controller,
    this.fishCount = 3,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    final fish = List.generate(fishCount, (i) => i);
    return Stack(
      children: fish.map((i) {
        final delay = i * 0.3;
        final verticalPos = 0.2 + (i * 0.25);
        final size = 24.0 + (i * 8.0);
        return Positioned(
          top: MediaQuery.of(context).size.height * verticalPos,
          left: 0,
          child: AnimatedBuilder(
            animation: controller,
            builder: (ctx, _) {
              final t = (controller.value + delay) % 1.0;
              final screenWidth = MediaQuery.of(context).size.width + 60;
              final x = (t * screenWidth) - 30;
              final flip = sin(t * 2 * pi);
              return Opacity(
                opacity: opacity,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setTranslationRaw(x, 0, 0)
                    ..setEntry(0, 0, flip > 0 ? -1.0 : 1.0)
                    ..setEntry(1, 1, 1.0)
                    ..setEntry(2, 2, 1.0),
                  child: Icon(
                    Icons.set_meal,
                    size: size,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
