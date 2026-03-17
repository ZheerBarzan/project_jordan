import 'package:project_jordan/model/teams.dart';

class TeamStanding {
  const TeamStanding({
    required this.team,
    required this.conferenceRecord,
    required this.conferenceRank,
    required this.divisionRecord,
    required this.divisionRank,
    required this.wins,
    required this.losses,
    required this.homeRecord,
    required this.roadRecord,
    required this.season,
  });

  final Team team;
  final String conferenceRecord;
  final int conferenceRank;
  final String divisionRecord;
  final int divisionRank;
  final int wins;
  final int losses;
  final String homeRecord;
  final String roadRecord;
  final int season;

  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    return TeamStanding(
      team: Team.fromJson(json['team'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      conferenceRecord: (json['conference_record'] ?? '').toString(),
      conferenceRank: json['conference_rank'] as int? ?? 0,
      divisionRecord: (json['division_record'] ?? '').toString(),
      divisionRank: json['division_rank'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      homeRecord: (json['home_record'] ?? '').toString(),
      roadRecord: (json['road_record'] ?? '').toString(),
      season: json['season'] as int? ?? 0,
    );
  }
}
