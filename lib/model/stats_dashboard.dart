import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/model/teams.dart';

class StatsDashboard {
  const StatsDashboard({
    required this.season,
    required this.teamsById,
    required this.standings,
    required this.teamStatsById,
    required this.leadersByStat,
    required this.warnings,
  });

  final int season;
  final Map<int, Team> teamsById;
  final List<TeamStanding> standings;
  final Map<int, TeamSeasonStats> teamStatsById;
  final Map<String, List<PlayerLeader>> leadersByStat;
  final List<String> warnings;

  List<TeamStanding> standingsForConference(String conference) {
    final String normalized = conference.toLowerCase();
    final List<TeamStanding> filtered =
        standings
            .where(
              (TeamStanding standing) =>
                  standing.team.conference.toLowerCase() == normalized,
            )
            .toList()
          ..sort(
            (TeamStanding a, TeamStanding b) =>
                a.conferenceRank.compareTo(b.conferenceRank),
          );
    return filtered;
  }
}
