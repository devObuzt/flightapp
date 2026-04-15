class Airport {
  const Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });

  final String code;
  final String name;
  final String city;
  final String country;

  factory Airport.fromJson(Map<String, dynamic> json) => Airport(
        code: json['code'] as String,
        name: json['name'] as String,
        city: json['city'] as String,
        country: json['country'] as String,
      );

  String get displayName => '$city ($code)';
}
