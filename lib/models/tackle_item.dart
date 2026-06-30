/// A tackle item in the user's tackle box.
class TackleItem {
  final int? id;
  final String name;
  final String type; // spinnerbait, crankbait, jig, soft_plastic, spoon, topwater, etc.
  final String? photoPath;
  final List<String> targetSpecies;
  final String tips;
  final DateTime createdAt;

  TackleItem({
    this.id,
    required this.name,
    required this.type,
    this.photoPath,
    this.targetSpecies = const [],
    this.tips = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type,
        'photo_path': photoPath,
        'target_species': targetSpecies.join('||'),
        'tips': tips,
        'created_at': createdAt.toIso8601String(),
      };

  factory TackleItem.fromMap(Map<String, dynamic> map) => TackleItem(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        photoPath: map['photo_path'] as String?,
        targetSpecies: (map['target_species'] as String? ?? '')
            .split('||')
            .where((s) => s.isNotEmpty)
            .toList(),
        tips: map['tips'] as String? ?? '',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  TackleItem copyWith({
    int? id,
    String? name,
    String? type,
    String? photoPath,
    List<String>? targetSpecies,
    String? tips,
    DateTime? createdAt,
  }) =>
      TackleItem(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        photoPath: photoPath ?? this.photoPath,
        targetSpecies: targetSpecies ?? this.targetSpecies,
        tips: tips ?? this.tips,
        createdAt: createdAt ?? this.createdAt,
      );
}
