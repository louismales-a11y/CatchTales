/// Tracks how many of each species an angler has caught during a trip.
class SpeciesTally {
  final int? id;
  final String angler;
  final String species;
  int count;
  final List<double> sizes; // inches

  SpeciesTally({
    this.id,
    required this.angler,
    required this.species,
    this.count = 1,
    List<double>? sizes,
  }) : sizes = sizes ?? [];

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'angler': angler,
        'species': species,
        'count': count,
        'sizes': sizes.map((s) => s.toStringAsFixed(1)).join(','),
      };

  factory SpeciesTally.fromMap(Map<String, dynamic> map) {
    var sizes = (map['sizes'] as String? ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s.trim()) ?? 0)
        .where((d) => d > 0)
        .toList();
    // Keep only the 5 largest
    sizes.sort((a, b) => b.compareTo(a));
    if (sizes.length > 5) sizes = sizes.sublist(0, 5);
    return SpeciesTally(
      id: map['id'] as int?,
      angler: map['angler'] as String,
      species: map['species'] as String,
      count: (map['count'] as num?)?.toInt() ?? 0,
      sizes: sizes,
    );
  }

  String get sizeDisplay {
    if (sizes.isEmpty) return '';
    if (sizes.length == 1) return '${sizes.first.toStringAsFixed(0)}"';
    final min = sizes.reduce((a, b) => a < b ? a : b);
    final max = sizes.reduce((a, b) => a > b ? a : b);
    if (min == max) return '${min.toStringAsFixed(0)}"';
    return '${min.toStringAsFixed(0)}"-${max.toStringAsFixed(0)}"';
  }
}

/// Angler with their total catch count and species breakdown.
class AnglerBreakdown {
  final String angler;
  final int total;
  final List<SpeciesTally> species;

  AnglerBreakdown({
    required this.angler,
    required this.total,
    required this.species,
  });
}
