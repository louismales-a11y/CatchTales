/// Tracks how many of each species an angler has caught during a trip.
class SpeciesTally {
  final int? id;
  final String angler;
  final String species;
  int count;

  SpeciesTally({
    this.id,
    required this.angler,
    required this.species,
    this.count = 1,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'angler': angler,
        'species': species,
        'count': count,
      };

  factory SpeciesTally.fromMap(Map<String, dynamic> map) => SpeciesTally(
        id: map['id'] as int?,
        angler: map['angler'] as String,
        species: map['species'] as String,
        count: (map['count'] as num?)?.toInt() ?? 0,
      );
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
