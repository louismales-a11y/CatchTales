import 'dart:math';
import 'package:flutter/material.dart';

/// Fish species types for variety.
enum FishSpecies {
  bass,       // Stocky, deep body
  pike,       // Long, narrow, torpedo-shaped
  trout,      // Streamlined, sleek
  sunfish,    // Round, small, pan-shaped
  catfish,    // Wide head, tapering body
}

/// Paints a realistic fish silhouette.
class FishPainter extends CustomPainter {
  final FishSpecies species;
  final Color color;
  final double sizeScale;

  FishPainter({
    this.species = FishSpecies.bass,
    this.color = Colors.white,
    this.sizeScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final bodyLen = w * 0.85;
    final bodyH = h * 0.5;

    switch (species) {
      case FishSpecies.bass:
        _drawBass(canvas, paint, cx, cy, bodyLen, bodyH);
        break;
      case FishSpecies.pike:
        _drawPike(canvas, paint, cx, cy, bodyLen, bodyH);
        break;
      case FishSpecies.trout:
        _drawTrout(canvas, paint, cx, cy, bodyLen, bodyH);
        break;
      case FishSpecies.sunfish:
        _drawSunfish(canvas, paint, cx, cy, bodyLen, bodyH);
        break;
      case FishSpecies.catfish:
        _drawCatfish(canvas, paint, cx, cy, bodyLen, bodyH);
        break;
    }
  }

  void _drawBass(Canvas canvas, Paint paint, double cx, double cy, double bl, double bh) {
    final path = Path();
    // Head (mouth at left)
    path.moveTo(cx - bl / 2, cy);
    // Top curve
    path.cubicTo(
      cx - bl * 0.3, cy - bh * 1.1,
      cx + bl * 0.1, cy - bh * 0.9,
      cx + bl / 2, cy - bh * 0.1,
    );
    // Tail top
    path.lineTo(cx + bl / 2 + bh * 0.3, cy - bh * 0.4);
    path.lineTo(cx + bl / 2 + bh * 0.4, cy);
    path.lineTo(cx + bl / 2 + bh * 0.3, cy + bh * 0.4);
    // Bottom curve back
    path.cubicTo(
      cx + bl * 0.1, cy + bh * 0.7,
      cx - bl * 0.3, cy + bh * 0.9,
      cx - bl / 2, cy,
    );
    path.close();
    canvas.drawPath(path, paint);
    // Eye
    _drawEye(canvas, cx - bl * 0.3, cy - bh * 0.15, bh * 0.08);
    // Dorsal fin
    _drawDorsal(canvas, paint, cx + bl * 0.0, cy - bh * 0.8, bh * 0.3);
  }

  void _drawPike(Canvas canvas, Paint paint, double cx, double cy, double bl, double bh) {
    final path = Path();
    // Long, narrow body - Pike
    path.moveTo(cx - bl / 2, cy);
    // Top
    path.cubicTo(
      cx - bl * 0.3, cy - bh * 0.6,
      cx + bl * 0.1, cy - bh * 0.5,
      cx + bl / 2, cy - bh * 0.1,
    );
    // Tail fork
    path.lineTo(cx + bl / 2 + bh * 0.4, cy - bh * 0.5);
    path.lineTo(cx + bl / 2 + bh * 0.5, cy);
    path.lineTo(cx + bl / 2 + bh * 0.4, cy + bh * 0.5);
    // Bottom
    path.cubicTo(
      cx + bl * 0.1, cy + bh * 0.4,
      cx - bl * 0.3, cy + bh * 0.5,
      cx - bl / 2, cy,
    );
    path.close();
    canvas.drawPath(path, paint);
    // Elongated jaw
    final jawPath = Path();
    jawPath.moveTo(cx - bl / 2, cy - bh * 0.05);
    jawPath.lineTo(cx - bl * 0.55, cy);
    jawPath.lineTo(cx - bl / 2, cy + bh * 0.05);
    jawPath.close();
    canvas.drawPath(jawPath, paint);
    // Eye
    _drawEye(canvas, cx - bl * 0.25, cy - bh * 0.1, bh * 0.06);
  }

  void _drawTrout(Canvas canvas, Paint paint, double cx, double cy, double bl, double bh) {
    final path = Path();
    // Streamlined body
    path.moveTo(cx - bl / 2, cy);
    path.cubicTo(
      cx - bl * 0.25, cy - bh * 0.8,
      cx + bl * 0.15, cy - bh * 0.7,
      cx + bl / 2, cy - bh * 0.1,
    );
    // Tail
    path.lineTo(cx + bl / 2 + bh * 0.35, cy - bh * 0.35);
    path.lineTo(cx + bl / 2 + bh * 0.45, cy);
    path.lineTo(cx + bl / 2 + bh * 0.35, cy + bh * 0.35);
    // Bottom
    path.cubicTo(
      cx + bl * 0.15, cy + bh * 0.6,
      cx - bl * 0.25, cy + bh * 0.7,
      cx - bl / 2, cy,
    );
    path.close();
    canvas.drawPath(path, paint);
    // Adipose fin (small fin on back near tail)
    final adiposePath = Path();
    adiposePath.moveTo(cx + bl * 0.3, cy - bh * 0.5);
    adiposePath.lineTo(cx + bl * 0.35, cy - bh * 0.7);
    adiposePath.lineTo(cx + bl * 0.4, cy - bh * 0.5);
    adiposePath.close();
    canvas.drawPath(adiposePath, paint);
    // Eye
    _drawEye(canvas, cx - bl * 0.25, cy - bh * 0.1, bh * 0.07);
  }

  void _drawSunfish(Canvas canvas, Paint paint, double cx, double cy, double bl, double bh) {
    final path = Path();
    // Round, disc-shaped body
    path.moveTo(cx - bl / 2, cy);
    // Top dome
    path.cubicTo(
      cx - bl * 0.3, cy - bh * 1.0,
      cx + bl * 0.2, cy - bh * 1.0,
      cx + bl / 2, cy - bh * 0.1,
    );
    // Tail
    path.lineTo(cx + bl / 2 + bh * 0.25, cy - bh * 0.3);
    path.lineTo(cx + bl / 2 + bh * 0.35, cy);
    path.lineTo(cx + bl / 2 + bh * 0.25, cy + bh * 0.3);
    // Bottom
    path.cubicTo(
      cx + bl * 0.2, cy + bh * 0.8,
      cx - bl * 0.3, cy + bh * 0.9,
      cx - bl / 2, cy,
    );
    path.close();
    canvas.drawPath(path, paint);
    // Eye (proportionally larger)
    _drawEye(canvas, cx - bl * 0.25, cy - bh * 0.1, bh * 0.12);
    // Pectoral fin
    final finPath = Path();
    finPath.moveTo(cx - bl * 0.05, cy + bh * 0.1);
    finPath.lineTo(cx + bl * 0.05, cy + bh * 0.5);
    finPath.lineTo(cx - bl * 0.1, cy + bh * 0.15);
    finPath.close();
    canvas.drawPath(finPath, paint);
  }

  void _drawCatfish(Canvas canvas, Paint paint, double cx, double cy, double bl, double bh) {
    final path = Path();
    // Wide head, tapering body
    path.moveTo(cx - bl / 2, cy);
    // Top
    path.cubicTo(
      cx - bl * 0.2, cy - bh * 0.7,
      cx + bl * 0.1, cy - bh * 0.5,
      cx + bl / 2, cy - bh * 0.1,
    );
    // Tail
    path.lineTo(cx + bl / 2 + bh * 0.3, cy - bh * 0.35);
    path.lineTo(cx + bl / 2 + bh * 0.4, cy);
    path.lineTo(cx + bl / 2 + bh * 0.3, cy + bh * 0.35);
    // Bottom
    path.cubicTo(
      cx + bl * 0.1, cy + bh * 0.4,
      cx - bl * 0.2, cy + bh * 0.6,
      cx - bl / 2, cy,
    );
    path.close();
    canvas.drawPath(path, paint);
    // Barbels (whiskers)
    final barbelPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // Upper barbel
    canvas.drawLine(
      Offset(cx - bl * 0.45, cy - bh * 0.1),
      Offset(cx - bl * 0.6, cy - bh * 0.3),
      barbelPaint,
    );
    // Lower barbel
    canvas.drawLine(
      Offset(cx - bl * 0.45, cy + bh * 0.1),
      Offset(cx - bl * 0.6, cy + bh * 0.3),
      barbelPaint,
    );
    // Eye
    _drawEye(canvas, cx - bl * 0.25, cy - bh * 0.05, bh * 0.05);
  }

  void _drawEye(Canvas canvas, double x, double y, double r) {
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(Offset(x, y), r, eyePaint);
  }

  void _drawDorsal(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    path.moveTo(x - size * 0.3, y);
    path.lineTo(x, y - size * 0.8);
    path.lineTo(x + size * 0.3, y);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A widget that displays a fish silhouette of a given species.
class FishSilhouette extends StatelessWidget {
  final FishSpecies species;
  final double size;
  final Color color;

  const FishSilhouette({
    super.key,
    this.species = FishSpecies.bass,
    this.size = 40,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FishPainter(species: species, color: color),
      size: Size(size, size * 0.6),
    );
  }
}
