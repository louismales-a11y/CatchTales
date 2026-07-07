import 'dart:math';
import 'package:flutter/material.dart';

/// Fish species types for variety.
enum FishSpecies {
  pike,       // Long, narrow, torpedo with duckbill jaw
  perch,      // Tall body, spiny dorsal, striped pattern (silhouette)
  walleye,    // Large eyes, tapered, spiny/soft dorsal split
  bass,       // Stocky, large mouth, deep body
  sunfish,    // Round, pan-shaped, small mouth
}

/// Paints a realistic fish silhouette using smooth cubic bezier curves.
class FishPainter extends CustomPainter {
  final FishSpecies species;
  final Color color;

  FishPainter({this.species = FishSpecies.bass, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final s = size.width; // scale reference

    switch (species) {
      case FishSpecies.pike:
        _drawPike(canvas, paint, s);
        break;
      case FishSpecies.perch:
        _drawPerch(canvas, paint, s);
        break;
      case FishSpecies.walleye:
        _drawWalleye(canvas, paint, s);
        break;
      case FishSpecies.bass:
        _drawBass(canvas, paint, s);
        break;
      case FishSpecies.sunfish:
        _drawSunfish(canvas, paint, s);
        break;
    }
  }

  /// ─── Pike (Esox lucius) ───
  /// Long torpedo body, duckbill snout, forked tail, dorsal fin far back
  void _drawPike(Canvas canvas, Paint paint, double s) {
    final p = Path();
    // Start at nose tip
    p.moveTo(s * 0.02, s * 0.44);
    // Upper jaw (duckbill)
    p.cubicTo(s * 0.06, s * 0.38, s * 0.10, s * 0.36, s * 0.14, s * 0.40);
    // Head top
    p.cubicTo(s * 0.18, s * 0.35, s * 0.22, s * 0.33, s * 0.28, s * 0.34);
    // Back to dorsal fin
    p.cubicTo(s * 0.35, s * 0.33, s * 0.40, s * 0.34, s * 0.48, s * 0.32);
    // Dorsal fin
    p.cubicTo(s * 0.50, s * 0.30, s * 0.52, s * 0.26, s * 0.54, s * 0.30);
    p.cubicTo(s * 0.56, s * 0.30, s * 0.57, s * 0.31, s * 0.58, s * 0.32);
    // Tail peduncle to upper tail fork
    p.cubicTo(s * 0.62, s * 0.32, s * 0.68, s * 0.30, s * 0.78, s * 0.22);
    // Upper tail lobe
    p.cubicTo(s * 0.82, s * 0.20, s * 0.86, s * 0.18, s * 0.88, s * 0.20);
    p.lineTo(s * 0.90, s * 0.40);
    // Tail fork center
    p.lineTo(s * 0.82, s * 0.44);
    // Lower tail lobe
    p.lineTo(s * 0.90, s * 0.56);
    p.lineTo(s * 0.88, s * 0.76);
    // Lower tail fork back
    p.cubicTo(s * 0.84, s * 0.78, s * 0.80, s * 0.76, s * 0.78, s * 0.74);
    // Lower peduncle
    p.cubicTo(s * 0.68, s * 0.66, s * 0.62, s * 0.64, s * 0.58, s * 0.64);
    // Anal fin
    p.cubicTo(s * 0.56, s * 0.64, s * 0.55, s * 0.66, s * 0.54, s * 0.64);
    // Belly
    p.cubicTo(s * 0.48, s * 0.64, s * 0.40, s * 0.62, s * 0.35, s * 0.62);
    // Lower jaw (duckbill)
    p.cubicTo(s * 0.28, s * 0.62, s * 0.20, s * 0.60, s * 0.14, s * 0.56);
    p.cubicTo(s * 0.10, s * 0.54, s * 0.06, s * 0.52, s * 0.02, s * 0.50);
    p.close();
    canvas.drawPath(p, paint);
    // Operculum/gill line
    final gill = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.5;
    canvas.drawPath(Path()..moveTo(s * 0.18, s * 0.38)..cubicTo(s * 0.20, s * 0.44, s * 0.18, s * 0.54, s * 0.16, s * 0.56), gill);
  }

  /// ─── Perch (Perca flavescens) ───
  /// Tall oval body, spiny dorsal (tall front), soft dorsal (low back), dark vertical bars
  void _drawPerch(Canvas canvas, Paint paint, double s) {
    final p = Path();
    p.moveTo(s * 0.04, s * 0.46);
    // Mouth
    p.cubicTo(s * 0.08, s * 0.40, s * 0.12, s * 0.38, s * 0.16, s * 0.40);
    // Forehead
    p.cubicTo(s * 0.18, s * 0.34, s * 0.22, s * 0.30, s * 0.28, s * 0.28);
    // Spiny dorsal fin (tall, spiky)
    p.cubicTo(s * 0.32, s * 0.22, s * 0.34, s * 0.14, s * 0.36, s * 0.10);
    p.cubicTo(s * 0.38, s * 0.10, s * 0.40, s * 0.14, s * 0.42, s * 0.18);
    // Dip between spiny and soft dorsal
    p.cubicTo(s * 0.44, s * 0.20, s * 0.46, s * 0.22, s * 0.48, s * 0.20);
    // Soft dorsal fin (lower, rounded)
    p.cubicTo(s * 0.50, s * 0.16, s * 0.52, s * 0.14, s * 0.54, s * 0.16);
    p.cubicTo(s * 0.56, s * 0.16, s * 0.58, s * 0.18, s * 0.60, s * 0.20);
    // Tail peduncle
    p.cubicTo(s * 0.64, s * 0.24, s * 0.66, s * 0.26, s * 0.70, s * 0.28);
    // Tail fin (slightly forked)
    p.cubicTo(s * 0.74, s * 0.24, s * 0.78, s * 0.22, s * 0.82, s * 0.24);
    p.lineTo(s * 0.86, s * 0.44);
    p.lineTo(s * 0.82, s * 0.62);
    p.cubicTo(s * 0.78, s * 0.64, s * 0.74, s * 0.62, s * 0.70, s * 0.58);
    // Lower peduncle
    p.cubicTo(s * 0.66, s * 0.56, s * 0.64, s * 0.54, s * 0.60, s * 0.54);
    // Anal fin
    p.cubicTo(s * 0.58, s * 0.54, s * 0.56, s * 0.56, s * 0.54, s * 0.54);
    p.cubicTo(s * 0.52, s * 0.56, s * 0.50, s * 0.52, s * 0.48, s * 0.56);
    // Belly
    p.cubicTo(s * 0.44, s * 0.58, s * 0.38, s * 0.60, s * 0.32, s * 0.60);
    // Lower jaw
    p.cubicTo(s * 0.26, s * 0.60, s * 0.20, s * 0.60, s * 0.16, s * 0.56);
    p.cubicTo(s * 0.12, s * 0.54, s * 0.08, s * 0.52, s * 0.04, s * 0.50);
    p.close();
    canvas.drawPath(p, paint);
    // Dark vertical bars (perch markings as notches)
    final bar = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final x = s * (0.22 + i * 0.10);
      canvas.drawLine(Offset(x, s * 0.30), Offset(x, s * 0.54), bar);
    }
  }

  /// ─── Walleye (Sander vitreus) ───
  /// Large eyes, tapered body, split dorsal (spiny front, soft back), white tail tip
  void _drawWalleye(Canvas canvas, Paint paint, double s) {
    final p = Path();
    p.moveTo(s * 0.04, s * 0.46);
    // Snout
    p.cubicTo(s * 0.08, s * 0.42, s * 0.12, s * 0.40, s * 0.16, s * 0.42);
    // Forehead
    p.cubicTo(s * 0.20, s * 0.36, s * 0.24, s * 0.32, s * 0.30, s * 0.30);
    // Spiny dorsal (moderate height)
    p.cubicTo(s * 0.34, s * 0.24, s * 0.36, s * 0.16, s * 0.38, s * 0.12);
    p.cubicTo(s * 0.40, s * 0.14, s * 0.42, s * 0.18, s * 0.44, s * 0.20);
    // Dip
    p.cubicTo(s * 0.46, s * 0.22, s * 0.48, s * 0.24, s * 0.50, s * 0.22);
    // Soft dorsal
    p.cubicTo(s * 0.52, s * 0.18, s * 0.54, s * 0.16, s * 0.56, s * 0.18);
    p.cubicTo(s * 0.58, s * 0.20, s * 0.60, s * 0.22, s * 0.64, s * 0.26);
    // Caudal peduncle
    p.cubicTo(s * 0.68, s * 0.28, s * 0.72, s * 0.30, s * 0.76, s * 0.32);
    // Tail (slightly forked, rounded)
    p.cubicTo(s * 0.80, s * 0.28, s * 0.84, s * 0.26, s * 0.88, s * 0.28);
    p.lineTo(s * 0.90, s * 0.44);
    p.lineTo(s * 0.88, s * 0.60);
    p.cubicTo(s * 0.84, s * 0.62, s * 0.80, s * 0.60, s * 0.76, s * 0.56);
    // Lower
    p.cubicTo(s * 0.72, s * 0.52, s * 0.68, s * 0.50, s * 0.64, s * 0.50);
    // Anal fin
    p.cubicTo(s * 0.62, s * 0.52, s * 0.60, s * 0.50, s * 0.58, s * 0.54);
    // Belly
    p.cubicTo(s * 0.52, s * 0.56, s * 0.44, s * 0.58, s * 0.36, s * 0.58);
    // Lower jaw
    p.cubicTo(s * 0.30, s * 0.58, s * 0.24, s * 0.58, s * 0.16, s * 0.54);
    p.cubicTo(s * 0.12, s * 0.52, s * 0.08, s * 0.50, s * 0.04, s * 0.48);
    p.close();
    canvas.drawPath(p, paint);
    // Large eye (walleye hallmark)
    final eye = Paint()..color = color;
    canvas.drawCircle(Offset(s * 0.18, s * 0.44), s * 0.035, eye);
  }

  /// ─── Bass (Micropterus salmoides) ───
  /// Large mouth, deep/compressed body, almost divided dorsal, wide tail
  void _drawBass(Canvas canvas, Paint paint, double s) {
    final p = Path();
    p.moveTo(s * 0.04, s * 0.46);
    // Large mouth
    p.cubicTo(s * 0.08, s * 0.38, s * 0.14, s * 0.34, s * 0.18, s * 0.36);
    // Forehead
    p.cubicTo(s * 0.22, s * 0.30, s * 0.28, s * 0.26, s * 0.34, s * 0.24);
    // Spiny dorsal
    p.cubicTo(s * 0.38, s * 0.18, s * 0.40, s * 0.12, s * 0.42, s * 0.08);
    p.cubicTo(s * 0.44, s * 0.10, s * 0.46, s * 0.14, s * 0.48, s * 0.16);
    // Dip
    p.cubicTo(s * 0.50, s * 0.18, s * 0.52, s * 0.20, s * 0.54, s * 0.18);
    // Soft dorsal
    p.cubicTo(s * 0.56, s * 0.12, s * 0.58, s * 0.10, s * 0.60, s * 0.12);
    p.cubicTo(s * 0.62, s * 0.14, s * 0.64, s * 0.18, s * 0.66, s * 0.22);
    // Caudal peduncle (thick)
    p.cubicTo(s * 0.70, s * 0.26, s * 0.74, s * 0.28, s * 0.78, s * 0.30);
    // Tail (large, slightly rounded)
    p.cubicTo(s * 0.82, s * 0.24, s * 0.86, s * 0.22, s * 0.90, s * 0.24);
    p.lineTo(s * 0.94, s * 0.44);
    p.lineTo(s * 0.90, s * 0.64);
    p.cubicTo(s * 0.86, s * 0.66, s * 0.82, s * 0.64, s * 0.78, s * 0.58);
    // Lower
    p.cubicTo(s * 0.74, s * 0.54, s * 0.70, s * 0.52, s * 0.66, s * 0.52);
    // Anal fin (rounded)
    p.cubicTo(s * 0.64, s * 0.54, s * 0.62, s * 0.52, s * 0.60, s * 0.56);
    // Belly (deep)
    p.cubicTo(s * 0.54, s * 0.60, s * 0.46, s * 0.62, s * 0.38, s * 0.62);
    // Lower jaw
    p.cubicTo(s * 0.32, s * 0.62, s * 0.24, s * 0.60, s * 0.18, s * 0.56);
    p.cubicTo(s * 0.12, s * 0.54, s * 0.08, s * 0.52, s * 0.04, s * 0.50);
    p.close();
    canvas.drawPath(p, paint);
  }

  /// ─── Sunfish (Lepomis macrochirus) ───
  /// Round disc body, small mouth, long dorsal, bright colors (silhouette is round)
  void _drawSunfish(Canvas canvas, Paint paint, double s) {
    final p = Path();
    p.moveTo(s * 0.04, s * 0.46);
    // Tiny mouth
    p.cubicTo(s * 0.08, s * 0.42, s * 0.10, s * 0.40, s * 0.14, s * 0.40);
    // Steep forehead (disc shape)
    p.cubicTo(s * 0.18, s * 0.30, s * 0.26, s * 0.22, s * 0.34, s * 0.18);
    // Long continuous dorsal
    p.cubicTo(s * 0.38, s * 0.12, s * 0.42, s * 0.06, s * 0.46, s * 0.04);
    p.cubicTo(s * 0.48, s * 0.04, s * 0.50, s * 0.06, s * 0.52, s * 0.06);
    p.cubicTo(s * 0.54, s * 0.06, s * 0.56, s * 0.08, s * 0.58, s * 0.10);
    // Taper to tail
    p.cubicTo(s * 0.62, s * 0.14, s * 0.66, s * 0.18, s * 0.70, s * 0.22);
    // Tail (small, rounded)
    p.cubicTo(s * 0.74, s * 0.20, s * 0.78, s * 0.18, s * 0.82, s * 0.20);
    p.lineTo(s * 0.86, s * 0.44);
    p.lineTo(s * 0.82, s * 0.68);
    p.cubicTo(s * 0.78, s * 0.70, s * 0.74, s * 0.68, s * 0.70, s * 0.66);
    // Lower body
    p.cubicTo(s * 0.66, s * 0.62, s * 0.62, s * 0.60, s * 0.58, s * 0.60);
    // Anal fin (mirrors dorsal)
    p.cubicTo(s * 0.54, s * 0.60, s * 0.52, s * 0.62, s * 0.50, s * 0.62);
    p.cubicTo(s * 0.48, s * 0.64, s * 0.46, s * 0.62, s * 0.44, s * 0.64);
    // Belly (rounded)
    p.cubicTo(s * 0.36, s * 0.66, s * 0.28, s * 0.64, s * 0.22, s * 0.58);
    // Lower jaw
    p.cubicTo(s * 0.16, s * 0.54, s * 0.10, s * 0.52, s * 0.04, s * 0.50);
    p.close();
    canvas.drawPath(p, paint);
    // Opercular flap (ear-like spot)
    final flap = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 0.5;
    canvas.drawArc(Rect.fromCircle(center: Offset(s * 0.22, s * 0.40), radius: s * 0.03), -pi * 0.5, pi * 1.5, false, flap);
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
