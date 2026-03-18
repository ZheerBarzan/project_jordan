class Player {
  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    this.teamId,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String position;
  final int? teamId;

  String get fullName => '$firstName $lastName'.trim();

  factory Player.fromJson(Map<String, dynamic> json) {
    final dynamic nestedTeam = json['team'];

    return Player(
      id: json['id'] as int? ?? 0,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      position: (json['position'] ?? '').toString(),
      teamId:
          json['team_id'] as int? ??
          (nestedTeam is Map<String, dynamic>
              ? nestedTeam['id'] as int?
              : null),
    );
  }
}
