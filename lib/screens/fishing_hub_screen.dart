import 'package:flutter/material.dart';
import '../services/fishing_guide_service.dart';
import '../models/fishing_guide.dart';
import 'fishing_region_screen.dart';

/// Shows all fishing regions within a province or state.
class FishingHubScreen extends StatefulWidget {
  final FishingHub hub;

  const FishingHubScreen({super.key, required this.hub});

  @override
  State<FishingHubScreen> createState() => _FishingHubScreenState();
}

class _FishingHubScreenState extends State<FishingHubScreen> {
  List<FishingRegion> _regions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final regions = await FishingGuideService.instance
        .getRegionsForHub(widget.hub.slug);
    if (mounted) {
      setState(() {
        _regions = regions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fishing in ${widget.hub.title}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hub description
                if (widget.hub.note.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      widget.hub.note,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (widget.hub.description.isNotEmpty &&
                    widget.hub.note.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      widget.hub.description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                // Stats
                if (widget.hub.stats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: widget.hub.stats.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            children: [
                              Text(
                                e.value,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                // Regions list
                Expanded(
                  child: _regions.isEmpty
                      ? Center(
                          child: Text(
                            'No region guides yet.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _regions.length,
                          itemBuilder: (context, index) {
                            final region = _regions[index];
                            final spotCount = region.spots.length;
                            // Extract species from spot names
                            final allSpecies = <String>{};
                            for (final spot in region.spots) {
                              allSpecies.addAll(spot.species);
                            }
                            final speciesList = allSpecies.take(4).join(', ');

                            return Card(
                              color: theme.colorScheme.surface.withValues(alpha: 0.8),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                isThreeLine: true,
                                title: Text(
                                  region.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (region.subtitle.isNotEmpty)
                                      Text(
                                        region.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _chip(theme, '$spotCount spots',
                                            theme.colorScheme.primary),
                                        if (speciesList.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: _chip(theme, speciesList,
                                                Colors.orange.withValues(alpha: 0.8)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FishingRegionScreen(region: region),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
