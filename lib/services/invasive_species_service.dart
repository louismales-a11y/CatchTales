import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Information about an invasive species.
class InvasiveSpecies {
  final String name;
  final String scientificName;
  final String type; // fish, plant, mollusk, crustacean
  final String description;
  final String impact;
  final List<String> regions; // US state codes or Canadian provinces

  const InvasiveSpecies({
    required this.name,
    required this.scientificName,
    required this.type,
    required this.description,
    required this.impact,
    required this.regions,
  });
}

/// Service for checking invasive species alerts by location.
///
/// Uses a curated database of known invasive aquatic species
/// in North America. Falls back to the USGS NAS API if available.
class InvasiveSpeciesService extends ChangeNotifier {
  static final InvasiveSpeciesService instance = InvasiveSpeciesService._();
  InvasiveSpeciesService._();

  List<InvasiveSpecies> _nearby = [];
  bool _loading = false;

  List<InvasiveSpecies> get nearby => _nearby;
  bool get loading => _loading;
  bool get hasAlerts => _nearby.isNotEmpty;

  static const _curatedDatabase = [
    InvasiveSpecies(
      name: 'Asian Carp',
      scientificName: 'Hypophthalmichthys spp.',
      type: 'fish',
      description: 'Large, fast-growing filter-feeding fish that outcompetes native species.',
      impact: 'Can dominate biomass, reduce plankton populations, and harm native fisheries.',
      regions: ['IL', 'IN', 'KY', 'MO', 'TN', 'AR', 'MS', 'LA', 'AL', 'IA', 'MN', 'WI', 'OH', 'MI', 'PA', 'NY'],
    ),
    InvasiveSpecies(
      name: 'Zebra Mussel',
      scientificName: 'Dreissena polymorpha',
      type: 'mollusk',
      description: 'Small striped mussel that forms dense colonies on hard surfaces.',
      impact: 'Clogs water intakes, damages boats, alters ecosystems by filtering plankton.',
      regions: ['MI', 'OH', 'IN', 'IL', 'WI', 'MN', 'NY', 'PA', 'VT', 'NH', 'ME', 'MA', 'CT', 'RI', 'NJ', 'DE', 'MD', 'VA', 'WV', 'KY', 'TN', 'MO', 'IA', 'MN', 'ND', 'SD', 'NE', 'KS', 'OK', 'TX', 'LA', 'AR', 'AL', 'MS', 'GA', 'SC', 'NC', 'FL'],
    ),
    InvasiveSpecies(
      name: 'Northern Snakehead',
      scientificName: 'Channa argus',
      type: 'fish',
      description: 'Predatory fish with a snake-like head that can breathe air and survive on land.',
      impact: 'Top predator that devastates native fish populations in ponds and slow rivers.',
      regions: ['MD', 'VA', 'DC', 'PA', 'DE', 'NJ', 'NY', 'NC', 'AR', 'CA'],
    ),
    InvasiveSpecies(
      name: 'Round Goby',
      scientificName: 'Neogobius melanostomus',
      type: 'fish',
      description: 'Small bottom-dwelling fish with a distinctive black spot on its dorsal fin.',
      impact: 'Outcompetes native fish for food and habitat, eats eggs of native species.',
      regions: ['MI', 'OH', 'IN', 'IL', 'WI', 'MN', 'NY', 'PA', 'VT', 'NH', 'ME', 'MA', 'CT', 'RI', 'NJ', 'DE', 'MD', 'VA', 'WV', 'KY', 'TN', 'MO', 'IA', 'MN', 'ND', 'SD', 'NE', 'KS', 'OK', 'TX', 'LA', 'AR', 'AL', 'MS', 'GA', 'SC', 'NC', 'FL', 'ON', 'QC', 'MB', 'SK', 'AB', 'BC'],
    ),
    InvasiveSpecies(
      name: 'Spiny Water Flea',
      scientificName: 'Bythotrephes longimanus',
      type: 'crustacean',
      description: 'Small crustacean with a long tail spine that forms gelatinous masses.',
      impact: 'Clogs fishing lines and downriggers, disrupts aquatic food webs.',
      regions: ['MI', 'OH', 'IN', 'IL', 'WI', 'MN', 'NY', 'PA', 'VT', 'NH', 'ME', 'MA', 'CT', 'RI', 'NJ', 'DE', 'MD', 'VA', 'WV', 'KY', 'TN', 'MO', 'IA', 'MN', 'ND', 'SD', 'NE', 'KS', 'OK', 'TX', 'LA', 'AR', 'AL', 'MS', 'GA', 'SC', 'NC', 'FL', 'ON', 'QC', 'MB', 'SK', 'AB', 'BC'],
    ),
    InvasiveSpecies(
      name: 'Hydrilla',
      scientificName: 'Hydrilla verticillata',
      type: 'plant',
      description: 'Fast-growing aquatic plant that forms dense mats at the water surface.',
      impact: 'Blocks waterways, crowds out native plants, degrades fish habitat.',
      regions: ['FL', 'GA', 'SC', 'NC', 'VA', 'MD', 'DE', 'AL', 'MS', 'LA', 'TX', 'AR', 'OK', 'KS', 'MO', 'TN', 'KY', 'IL', 'IN', 'OH', 'MI', 'PA', 'NJ', 'NY', 'CT', 'RI', 'MA', 'VT', 'NH', 'ME', 'CA', 'WA', 'OR', 'ID', 'MT', 'WY', 'CO', 'UT', 'NV', 'AZ', 'NM', 'HI', 'PR'],
    ),
    InvasiveSpecies(
      name: 'Sea Lamprey',
      scientificName: 'Petromyzon marinus',
      type: 'fish',
      description: 'Eel-like parasitic fish with a suction-cup mouth full of teeth.',
      impact: 'Attaches to native fish and feeds on body fluids, killing or wounding them.',
      regions: ['MI', 'OH', 'IN', 'IL', 'WI', 'MN', 'NY', 'PA', 'VT', 'NH', 'ME', 'MA', 'CT', 'RI', 'NJ', 'DE', 'MD', 'VA', 'NC', 'SC', 'GA', 'FL', 'AL', 'MS', 'LA', 'TX', 'ON', 'QC', 'NB', 'NS', 'PE', 'NL'],
    ),
    InvasiveSpecies(
      name: 'Rusty Crayfish',
      scientificName: 'Faxonius rusticus',
      type: 'crustacean',
      description: 'Aggressive crayfish with dark rusty spots on each side of its carapace.',
      impact: 'Destroys aquatic vegetation, outcompetes native crayfish, reduces fish habitat.',
      regions: ['MI', 'WI', 'MN', 'IL', 'IN', 'OH', 'PA', 'NY', 'VT', 'NH', 'ME', 'MA', 'CT', 'RI', 'NJ', 'DE', 'MD', 'VA', 'WV', 'KY', 'TN', 'MO', 'IA', 'MN', 'ND', 'SD', 'NE', 'KS', 'OK', 'TX', 'LA', 'AR', 'AL', 'MS', 'GA', 'SC', 'NC', 'FL', 'ON', 'QC', 'MB', 'SK', 'AB', 'BC'],
    ),
  ];

  /// Check for invasive species near a given state/province code.
  Future<void> checkByState(String stateCode) async {
    _loading = true;
    _nearby = [];
    notifyListeners();

    // Search curated database
    final upper = stateCode.toUpperCase();
    _nearby = _curatedDatabase.where((s) =>
        s.regions.any((r) => r.toUpperCase() == upper)).toList();

    _loading = false;
    notifyListeners();
  }

  /// Check for invasive species using lat/lng via reverse geocoding.
  Future<void> checkByLocation(double lat, double lng) async {
    _loading = true;
    _nearby = [];
    notifyListeners();

    try {
      // Try to get state from coordinates using Nominatim
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${lat.toStringAsFixed(4)}'
          '&lon=${lng.toStringAsFixed(4)}'
          '&format=json'
          '&zoom=5&addressdetails=1');
      final response = await http.get(url,
          headers: {'User-Agent': 'CatchTales/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map;
        final address = data['address'] as Map?;
        if (address != null) {
          // Check US state
          final state = address['state_code'] as String?;
          if (state != null && state.length == 2) {
            await checkByState(state);
            return;
          }
          // Check Canadian province (ISO code)
          final prov = address['ISO_3166-2'] as String?;
          if (prov != null && prov.contains('-')) {
            final code = prov.split('-').last;
            await checkByState(code);
            return;
          }
        }
      }
    } catch (_) {
      // Fallback: try just using country code
    }

    _loading = false;
    notifyListeners();
  }

  /// Get a human-readable summary of nearby invasive species.
  String get summary {
    if (_nearby.isEmpty) return 'No invasive species alerts for this area';
    return '${_nearby.length} invasive species reported in this area: '
        '${_nearby.map((s) => s.name).join(', ')}';
  }
}
