import 'package:flutter/material.dart';

// ─── Data Model ───────────────────────────────────────────────────────────

class FishSpecies {
  final String name;
  final String scientificName;
  final List<String> regions;
  final String sizeRange;
  final String habitat;
  final String waterType;
  final String diet;
  final String commonTackle;
  final String description;
  final List<String> tips;
  final Color color;
  final bool isProtected;

  const FishSpecies({
    required this.name,
    required this.scientificName,
    required this.regions,
    required this.sizeRange,
    required this.habitat,
    required this.waterType,
    required this.diet,
    required this.commonTackle,
    this.description = '',
    this.tips = const [],
    this.color = Colors.blue,
    this.isProtected = false,
  });
}
