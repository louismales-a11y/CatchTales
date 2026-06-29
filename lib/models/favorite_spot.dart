class FavoriteSpot {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? bestSpecies;
  final String? photoPath;
  final DateTime createdAt;

  FavoriteSpot({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.bestSpecies,
    this.photoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'best_species': bestSpecies,
        'photo_path': photoPath,
        'created_at': createdAt.toIso8601String(),
      };

  factory FavoriteSpot.fromMap(Map<String, dynamic> map) => FavoriteSpot(
        id: map['id'] as int?,
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        notes: map['notes'] as String?,
        bestSpecies: map['best_species'] as String?,
        photoPath: map['photo_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
