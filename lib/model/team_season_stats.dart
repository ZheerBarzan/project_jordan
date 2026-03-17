import 'package:project_jordan/model/teams.dart';

class TeamSeasonStats {
  const TeamSeasonStats({
    required this.team,
    required this.season,
    required this.seasonType,
    required this.wins,
    required this.losses,
    required this.gamesPlayed,
    required this.points,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.fieldGoalPct,
    required this.threePointPct,
    required this.plusMinus,
  });

  final Team team;
  final int season;
  final String seasonType;
  final int wins;
  final int losses;
  final int gamesPlayed;
  final double points;
  final double rebounds;
  final double assists;
  final double steals;
  final double blocks;
  final double fieldGoalPct;
  final double threePointPct;
  final double plusMinus;

  factory TeamSeasonStats.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> stats =
        json['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};

    double readDouble(String key) => (stats[key] as num?)?.toDouble() ?? 0;
    int readInt(String key) => (stats[key] as num?)?.toInt() ?? 0;

    return TeamSeasonStats(
      team: Team.fromJson(json['team'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      season: json['season'] as int? ?? 0,
      seasonType: (json['season_type'] ?? '').toString(),
      wins: readInt('w'),
      losses: readInt('l'),
      gamesPlayed: readInt('gp'),
      points: readDouble('pts'),
      rebounds: readDouble('reb'),
      assists: readDouble('ast'),
      steals: readDouble('stl'),
      blocks: readDouble('blk'),
      fieldGoalPct: readDouble('fg_pct'),
      threePointPct: readDouble('fg3_pct'),
      plusMinus: readDouble('plus_minus'),
    );
  }
}
