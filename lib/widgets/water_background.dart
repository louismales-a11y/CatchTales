import 'dart:math';
import 'package:flutter/material.dart';
import '../services/skin_service.dart';

/// Full-screen underwater background with animated fish silhouettes.
/// Each fish swims independently — when one exits left, it respawns
/// on the right with new random size/position/speed.
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
    this.overlayOpacity = 0.6,
  });

  @override
  State<WaterBackground> createState() => _WaterBackgroundState();
}

class _WaterBackgroundState extends State<WaterBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_AnimatedFish> _fish;

  final _fishPaths = [
    'assets/fish1.png',
    'assets/fish2.png',
    'assets/fish3.png',
    'assets/fish4.png',
    'assets/fish5.png',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _fish = List.generate(8, (_) => _AnimatedFish());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFancy = widget.showFish && SkinService.instance.isFancy;
    return Stack(
      children: [
        // Background (underwater image for Fancy, solid dark for Classic)
        if (isFancy)
          Positioned.fill(
            child: Image.asset(widget.imagePath, fit: BoxFit.cover),
          )
        else
          Positioned.fill(
            child: Container(color: const Color(0xFF0A0E1A)),
          ),
        // Dark overlay for readability (Fancy only)
        if (isFancy)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: widget.overlayOpacity),
            ),
          ),
        // Bubbles (Fancy only)
        if (isFancy)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (ctx, _) => CustomPaint(
                painter: _BubblePainter(progress: _controller.value),
                size: Size.infinite,
              ),
            ),
          ),
        // Fish (Fancy only)
        if (isFancy)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (ctx, _) {
                final size = MediaQuery.of(context).size;
                return Stack(
                  children: _fish.map((f) {
                    f.update();
                    final x = size.width * (1.0 - f.progress) - f.fishSize * 0.5;
                    final y = size.height * f.verticalPos +
                        sin(f.progress * f.bobFreq * 6.28) * f.bobAmplitude;
                    if (x < -f.fishSize || x > size.width + f.fishSize) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: f.opacity,
                        child: Image.asset(
                          _fishPaths[f.imageIndex % _fishPaths.length],
                          width: f.fishSize,
                          height: f.fishSize * 0.6,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.difference,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        // Content on top
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

/// One fish with its own independent animation state.
class _AnimatedFish {
  double progress;       // 0 = right edge, 1 = left edge
  late double verticalPos;
  late double fishSize;
  late double opacity;
  late double bobFreq;
  late double bobAmplitude;
  late double speed;
  late int imageIndex;

  static final _rand = Random();
  static int _nextIndex = 0;

  _AnimatedFish() : progress = _rand.nextDouble() {
    _randomize();
    imageIndex = _nextIndex++;
  }

  void _randomize() {
    verticalPos = 0.03 + _rand.nextDouble() * 0.9;
    fishSize = 25 + _rand.nextDouble() * 70;
    opacity = 0.08 + _rand.nextDouble() * 0.25;
    bobFreq = 1.5 + _rand.nextDouble() * 4;
    bobAmplitude = 4 + _rand.nextDouble() * 12;
    speed = 0.0004 + _rand.nextDouble() * 0.003;
  }

  /// Called every animation frame. Advances the fish across the screen.
  void update() {
    progress += speed;
    if (progress >= 1.0) {
      // Exited left — respawn on right with fresh random params
      progress = 0.0;
      _randomize();
    }
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
