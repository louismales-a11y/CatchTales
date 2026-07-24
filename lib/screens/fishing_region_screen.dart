import 'package:flutter/material.dart';
import '../models/fishing_guide.dart';

/// Shows details for a fishing region, including all its spots.
class FishingRegionScreen extends StatelessWidget {
  final FishingRegion region;

  const FishingRegionScreen({super.key, required this.region});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(region.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          if (region.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                region.subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          if (region.intro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                region.intro,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ),
          // Spots
          ...region.spots.map((spot) => _SpotCard(spot: spot, theme: theme)),
          if (region.spots.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No specific spots listed for this region.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final FishingSpot spot;
  final ThemeData theme;

  const _SpotCard({required this.spot, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              spot.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Distance / location
            if (spot.distance.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  spot.distance,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Species chips
            if (spot.species.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: spot.species.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      s.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            // Description
            if (spot.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                spot.description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
