class Catch {
  final int? id;
  final String angler;
  final String species;
  final String location;
  final String lure;
  final List<String>? photoPaths;
  final double? weight;
  final String weightUnit;
  final double? length;
  final String lengthUnit;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? tripName;
  final String? waterClarity;
  final String? flowRate;
  final double? weatherTemp;
  final String? weatherCondition;
  final DateTime caughtAt;
  final DateTime createdAt;

  Catch({
    this.id,
    required this.angler,
    required this.species,
    this.location = '',
    this.lure = '',
    this.photoPaths,
    this.weight,
    this.weightUnit = 'kg',
    this.length,
    this.lengthUnit = 'cm',
    this.latitude,
    this.longitude,
    this.notes,
    this.tripName,
    this.waterClarity,
    this.flowRate,
    this.weatherTemp,
    this.weatherCondition,
    DateTime? caughtAt,
    DateTime? createdAt,
  })  : caughtAt = caughtAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  String? get primaryPhoto =>
      photoPaths?.isNotEmpty == true ? photoPaths!.first : null;
  bool get hasPhotos => photoPaths?.isNotEmpty == true;

  String get weightDisplay {
    if (weight == null) return '';
    final f = weight! == weight!.roundToDouble()
        ? weight!.toInt().toString()
        : weight!.toStringAsFixed(1);
    return '$f $weightUnit';
  }

  String get lengthDisplay {
    if (length == null) return '';
    final f = length! == length!.roundToDouble()
        ? length!.toInt().toString()
        : length!.toStringAsFixed(1);
    return '$f $lengthUnit';
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'angler': angler,
        'species': species,
        'location': location,
        'lure': lure,
        'photo_paths': photoPaths?.join('|'),
        'weight': weight,
        'weight_unit': weightUnit,
        'length': length,
        'length_unit': lengthUnit,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'trip_name': tripName,
        'water_clarity': waterClarity,
        'flow_rate': flowRate,
        'weather_temp': weatherTemp,
        'weather_condition': weatherCondition,
        'caught_at': caughtAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Catch.fromMap(Map<String, dynamic> map) {
    List<String>? paths;
    final p = map['photo_paths'] as String?;
    if (p != null && p.isNotEmpty) {
      paths = p.split('|').where((s) => s.isNotEmpty).toList();
    }
    return Catch(
        id: map['id'] as int?,
        angler: map['angler'] as String,
        species: map['species'] as String,
        location: (map['location'] as String?) ?? '',
        lure: (map['lure'] as String?) ?? '',
        photoPaths: paths,
        weight: (map['weight'] as num?)?.toDouble(),
        weightUnit: (map['weight_unit'] as String?) ?? 'kg',
        length: (map['length'] as num?)?.toDouble(),
        lengthUnit: (map['length_unit'] as String?) ?? 'cm',
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
        tripName: map['trip_name'] as String?,
        waterClarity: map['water_clarity'] as String?,
        flowRate: map['flow_rate'] as String?,
        weatherTemp: (map['weather_temp'] as num?)?.toDouble(),
        weatherCondition: map['weather_condition'] as String?,
        caughtAt: DateTime.parse(map['caught_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
  }

  Catch copyWith({
    int? id,
    String? angler,
    String? species,
    String? location,
    String? lure,
    List<String>? photoPaths,
    double? weight,
    String? weightUnit,
    double? length,
    String? lengthUnit,
    double? latitude,
    double? longitude,
    String? notes,
    String? tripName,
    String? waterClarity,
    String? flowRate,
    double? weatherTemp,
    String? weatherCondition,
    DateTime? caughtAt,
    DateTime? createdAt,
  }) =>
      Catch(
        id: id ?? this.id,
        angler: angler ?? this.angler,
        species: species ?? this.species,
        location: location ?? this.location,
        lure: lure ?? this.lure,
        photoPaths: photoPaths ?? this.photoPaths,
        weight: weight ?? this.weight,
        weightUnit: weightUnit ?? this.weightUnit,
        length: length ?? this.length,
        lengthUnit: lengthUnit ?? this.lengthUnit,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        notes: notes ?? this.notes,
        tripName: tripName ?? this.tripName,
        waterClarity: waterClarity ?? this.waterClarity,
        flowRate: flowRate ?? this.flowRate,
        weatherTemp: weatherTemp ?? this.weatherTemp,
        weatherCondition: weatherCondition ?? this.weatherCondition,
        caughtAt: caughtAt ?? this.caughtAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
