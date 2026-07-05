class DepthReading {
  final int? id;
  final double latitude;
  final double longitude;
  final double depthFeet;
  final String? angler;
  final DateTime loggedAt;

  DepthReading({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.depthFeet,
    this.angler,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'depth_feet': depthFeet,
        'angler': angler,
        'logged_at': loggedAt.toIso8601String(),
      };

  factory DepthReading.fromMap(Map<String, dynamic> map) => DepthReading(
        id: map['id'] as int?,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        depthFeet: (map['depth_feet'] as num).toDouble(),
        angler: map['angler'] as String?,
        loggedAt: DateTime.parse(map['logged_at'] as String),
      );
}
