class FishCounter {
  final int? id;
  final String angler;
  int count;

  FishCounter({
    this.id,
    required this.angler,
    this.count = 0,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'angler': angler,
        'count': count,
      };

  factory FishCounter.fromMap(Map<String, dynamic> map) => FishCounter(
        id: map['id'] as int?,
        angler: map['angler'] as String,
        count: (map['count'] as num?)?.toInt() ?? 0,
      );
}
