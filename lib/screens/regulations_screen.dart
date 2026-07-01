import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/help_text.dart';

class RegulationsScreen extends StatelessWidget {
  const RegulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Regulations'),
        actions: [helpButton(context, 'regulations')],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(Icons.description, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text('Canadian Fishing Regulations',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tap a province to view its official fishing guide',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Manitoba (home province) — highlighted
          _ProvinceCard(
            name: 'Manitoba',
            emoji: '🏠',
            url: 'https://gov.mb.ca/fish/fish.html',
            color: theme.colorScheme.primary,
            isHome: true,
          ),
          const SizedBox(height: 16),

          // Other provinces
          Text('Provinces', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _ProvinceCard(name: 'Ontario', emoji: '🇨🇦', url: 'https://www.ontario.ca/fishing'),
          _ProvinceCard(name: 'Saskatchewan', emoji: '🇨🇦', url: 'https://www.saskatchewan.ca/fishing'),
          _ProvinceCard(name: 'Alberta', emoji: '🇨🇦', url: 'https://www.alberta.ca/recreation'),
          _ProvinceCard(name: 'British Columbia', emoji: '🇨🇦', url: 'https://www2.gov.bc.ca/gov/content/environment/plants-animals-ecosystems/fish/aquatic-species/bc-fish-species'),
          _ProvinceCard(name: 'Quebec', emoji: '🇨🇦', url: 'https://www.quebec.ca/en/loisirs/peche'),
          const SizedBox(height: 16),

          // Territories
          Text('Territories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _ProvinceCard(name: 'Yukon', emoji: '🇨🇦', url: 'https://yukon.ca/fishing'),
          _ProvinceCard(name: 'Northwest Territories', emoji: '🇨🇦', url: 'https://www.nwt.ca/fishing'),
          _ProvinceCard(name: 'Nunavut', emoji: '🇨🇦', url: 'https://www.gov.nu.ca/fishing'),
          const SizedBox(height: 16),

          // Atlantic
          Text('Atlantic Canada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          _ProvinceCard(name: 'New Brunswick', emoji: '🇨🇦', url: 'https://www2.gnb.ca/content/gnb/en/departments/erd.html'),
          _ProvinceCard(name: 'Nova Scotia', emoji: '🇨🇦', url: 'https://novascotia.ca/fish/'),
          _ProvinceCard(name: 'Prince Edward Island', emoji: '🇨🇦', url: 'https://www.princeedwardisland.ca/en/information/environment-energy-and-climate-action/fishing'),
          _ProvinceCard(name: 'Newfoundland & Labrador', emoji: '🇨🇦', url: 'https://www.gov.nl.ca/ecc/'),
          const SizedBox(height: 32),

          // Note
          Center(
            child: Text(
              'Regulations are set by each province/territory.\nAlways check local rules before fishing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProvinceCard extends StatelessWidget {
  final String name;
  final String emoji;
  final String url;
  final Color? color;
  final bool isHome;

  const _ProvinceCard({
    required this.name,
    required this.emoji,
    required this.url,
    this.color,
    this.isHome = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isHome ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHome ? BorderSide(color: theme.colorScheme.primary, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHome
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          radius: 18,
          child: Text(isHome ? '🏠' : '📄', style: const TextStyle(fontSize: 18)),
        ),
        title: Text(name,
            style: TextStyle(fontWeight: FontWeight.w600, color: isHome ? theme.colorScheme.primary : null)),
        subtitle: isHome ? const Text('Home province', style: TextStyle(fontSize: 11)) : null,
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
  }
}
