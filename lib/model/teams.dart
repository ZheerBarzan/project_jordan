class Team {
  final int id;
  final String abbreviation;
  final String city;
  final String conference;
  final String division;
  final String fullName;
  final String name;

  Team({
    required this.id,
    required this.abbreviation,
    required this.city,
    required this.conference,
    required this.division,
    required this.fullName,
    required this.name,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int? ?? 0,
      abbreviation: (json['abbreviation'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      conference: (json['conference'] ?? '').toString(),
      division: (json['division'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
