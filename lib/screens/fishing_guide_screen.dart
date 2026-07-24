import 'package:flutter/material.dart';
import '../services/fishing_guide_service.dart';
import '../models/fishing_guide.dart';
import 'fishing_hub_screen.dart';

/// Main fishing guide screen: lists all provinces and states grouped by country.
class FishingGuideScreen extends StatefulWidget {
  const FishingGuideScreen({super.key});

  @override
  State<FishingGuideScreen> createState() => _FishingGuideScreenState();
}

class _FishingGuideScreenState extends State<FishingGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FishingHub> _canadaHubs = [];
  List<FishingHub> _usHubs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final service = FishingGuideService.instance;
      final canada = await service.getHubsByCountry('ca');
      final us = await service.getHubsByCountry('us');
      if (mounted) {
        setState(() {
          _canadaHubs = canada;
          _usHubs = us;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('FishingGuideScreen._load error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Guides'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇨🇦', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text('Canada (${_canadaHubs.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇺🇸', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text('United States (${_usHubs.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHubList(context, _canadaHubs, theme),
                _buildHubList(context, _usHubs, theme),
              ],
            ),
    );
  }

  Widget _buildHubList(BuildContext context, List<FishingHub> hubs, ThemeData theme) {
    if (hubs.isEmpty) {
      return Center(
        child: Text(
          'No guides available yet.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: hubs.length,
      itemBuilder: (context, index) {
        final hub = hubs[index];
        return Card(
          color: theme.colorScheme.surface.withValues(alpha: 0.8),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: hub.isCanada
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              child: Text(
                hub.title.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  color: hub.isCanada ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Fishing in ${hub.title}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hub.description.isNotEmpty)
                  Text(
                    hub.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                if (hub.regions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${hub.regions.length} regions',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FishingHubScreen(hub: hub),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
