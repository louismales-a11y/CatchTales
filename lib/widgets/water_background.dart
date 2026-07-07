import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen underwater background image with animated fish silhouettes.
/// Use as a Stack background behind your content.
class WaterBackground extends StatefulWidget {
  final Widget? child;
  final bool showFish;
  final String imagePath;
  final double overlayOpacity;

  const WaterBackground({
    super.key,
    this.child,
    this.showFish = true,
    this.imagePath = 'assets/underwater.png',
    this.overlayOpacity = 0.5,
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
      duration: const Duration(seconds: 12),
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
        // Background image
        Positioned.fill(
          child: Image.asset(widget.imagePath, fit: BoxFit.cover),
        ),
        // Dark overlay for readability
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: widget.overlayOpacity),
          ),
        ),
        // Subtle animated bubbles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (ctx, _) => CustomPaint(
              painter: _BubblePainter(progress: _controller.value),
              size: Size.infinite,
            ),
          ),
        ),
        // Fish silhouettes
        if (widget.showFish)
          _FishBuilder(controller: _controller, fishCount: 4, opacity: 0.2),
        // Content on top
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

/// Paints subtle floating bubbles.
class _BubblePainter extends CustomPainter {
  final double progress;
  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 8; i++) {
      final t = (progress + i * 0.125) % 1.0;
      final x = size.width * (0.1 + (i * 0.1) + sin(t * 2 * pi) * 0.05);
      final y = size.height * (1.0 - t);
      final r = 3.0 + sin(t * pi) * 4.0;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.progress != progress;
}

/// Builds animated fish using a single repaint boundary.
class _FishBuilder extends StatelessWidget {
  final AnimationController controller;
  final int fishCount;
  final double opacity;

  const _FishBuilder({
    required this.controller,
    this.fishCount = 4,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final size = MediaQuery.of(context).size;
        return Stack(
          children: List.generate(fishCount, (i) {
            final delay = i * 0.25;
            final t = (controller.value + delay) % 1.0;
            final verticalPos = 0.15 + (i * 0.2);
            final fishSize = 20.0 + (i * 10.0);
            final verticalBob = (i % 2 == 0) ? 0.0 : 10.0;
            final x = (t * (size.width + 80)) - 40;
            final y = (size.height * verticalPos) + sin(t * 4 * pi) * verticalBob;
            final flip = cos(t * 2 * pi) > 0;

            return Positioned(
              top: y,
              left: x,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..setEntry(0, 0, flip ? -1.0 : 1.0),
                child: Opacity(
                  opacity: opacity,
                  child: Icon(Icons.set_meal, size: fishSize, color: Colors.white),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
