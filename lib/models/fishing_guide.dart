/// A province or state hub (e.g. Manitoba, Florida)
class FishingHub {
  final String slug;
  final String title;
  final String description;
  final String note;
  final List<String> regions;
  final Map<String, String> stats;
  final String country; // 'ca' or 'us'

  FishingHub({
    required this.slug,
    required this.title,
    required this.description,
    this.note = '',
    required this.regions,
    this.stats = const {},
    required this.country,
  });

  factory FishingHub.fromJson(Map<String, dynamic> json) => FishingHub(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    note: json['note'] as String? ?? '',
    regions: (json['regions'] as List<dynamic>?)?.cast<String>() ?? [],
    stats: (json['stats'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v.toString())
    ) ?? {},
    country: json['country'] as String? ?? 'us',
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
    'note': note,
    'regions': regions,
    'stats': stats,
    'country': country,
  };

  String get displayName => title;
  bool get isCanada => country == 'ca';
}

/// A fishing spot within a region
class FishingSpot {
  final String name;
  final String distance;
  final String description;
  final List<String> species;

  FishingSpot({
    required this.name,
    this.distance = '',
    this.description = '',
    this.species = const [],
  });

  factory FishingSpot.fromJson(Map<String, dynamic> json) => FishingSpot(
    name: json['name'] as String? ?? '',
    distance: json['distance'] as String? ?? '',
    description: json['description'] as String? ?? '',
    species: (json['species'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'distance': distance,
    'description': description,
    'species': species,
  };
}

/// A fishing region (e.g. Fishing Near Winnipeg)
class FishingRegion {
  final String slug;
  final String title;
  final String subtitle;
  final String description;
  final String intro;
  final List<FishingSpot> spots;
  final String parentHub;
  final String country;

  FishingRegion({
    required this.slug,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.intro = '',
    this.spots = const [],
    this.parentHub = '',
    this.country = 'ca',
  });

  factory FishingRegion.fromJson(Map<String, dynamic> json) => FishingRegion(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    description: json['description'] as String? ?? '',
    intro: json['intro'] as String? ?? '',
    spots: (json['spots'] as List<dynamic>?)
        ?.map((s) => FishingSpot.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
    parentHub: json['parent_hub'] as String? ?? '',
    country: json['country'] as String? ?? 'ca',
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'intro': intro,
    'spots': spots.map((s) => s.toJson()).toList(),
    'parent_hub': parentHub,
    'country': country,
  };

  bool get isCanada => country == 'ca';
}

/// A blog post summary
class BlogPost {
  final String slug;
  final String title;
  final String description;
  final String intro;

  BlogPost({
    required this.slug,
    required this.title,
    this.description = '',
    this.intro = '',
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    intro: json['intro'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'description': description,
    'intro': intro,
  };
}
