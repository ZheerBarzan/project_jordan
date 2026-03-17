import 'package:project_jordan/model/player.dart';

class PlayerLeader {
  const PlayerLeader({
    required this.player,
    required this.value,
    required this.statType,
    required this.rank,
    required this.season,
    required this.gamesPlayed,
  });

  final Player player;
  final double value;
  final String statType;
  final int rank;
  final int season;
  final int gamesPlayed;

  factory PlayerLeader.fromJson(Map<String, dynamic> json) {
    return PlayerLeader(
      player: Player.fromJson(json['player'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      statType: (json['stat_type'] ?? '').toString(),
      rank: json['rank'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      gamesPlayed: json['games_played'] as int? ?? 0,
    );
  }
}
