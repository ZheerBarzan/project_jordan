import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/stats_dashboard.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:project_jordan/services/nba_api_service.dart';

abstract class BasketballDataRepository {
  Future<List<Game>> fetchGamesForDate(DateTime date);

  Future<List<Game>> fetchRecentGames({int days});

  Future<StatsDashboard> fetchStatsDashboard({required int season});
}

class BasketballRepository implements BasketballDataRepository {
  BasketballRepository({NbaApiService? service})
      : _service = service ?? NbaApiService();

  static const List<String> defaultLeaderStats = <String>[
    'pts',
    'reb',
    'ast',
    'stl',
    'blk',
  ];

  final NbaApiService _service;

  @override
  Future<List<Game>> fetchGamesForDate(DateTime date) async {
    final List<Game> games = await _service.fetchGames(dates: <DateTime>[date]);
    return _sortGames(games);
  }

  @override
  Future<List<Game>> fetchRecentGames({int days = 4}) async {
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(Duration(days: days - 1));
    final List<Game> games = await _service.fetchGames(
      startDate: startDate,
      endDate: today,
    );
    return _sortGames(games);
  }

  @override
  Future<StatsDashboard> fetchStatsDashboard({required int season}) async {
    final List<Team> teams = await _service.fetchTeams();
    final Map<int, Team> teamsById = <int, Team>{
      for (final Team team in teams) team.id: team,
    };

    final List<String> warnings = <String>[];
    List<TeamStanding> standings = <TeamStanding>[];
    Map<int, TeamSeasonStats> teamStatsById = <int, TeamSeasonStats>{};
    final Map<String, List<PlayerLeader>> leadersByStat =
        <String, List<PlayerLeader>>{};

    try {
      standings = await _service.fetchStandings(season: season);
    } catch (error) {
      warnings.add('Standings unavailable: $error');
    }

    try {
      final List<TeamSeasonStats> teamStats =
          await _service.fetchTeamSeasonStats(season: season);
      teamStatsById = <int, TeamSeasonStats>{
        for (final TeamSeasonStats stats in teamStats) stats.team.id: stats,
      };
    } catch (error) {
      warnings.add('Team season stats unavailable: $error');
    }

    await Future.wait(
      defaultLeaderStats.map((String statType) async {
        try {
          leadersByStat[statType] = await _service.fetchLeaders(
            season: season,
            statType: statType,
          );
        } catch (error) {
          warnings.add('${_labelForStat(statType)} leaders unavailable: $error');
        }
      }),
    );

    return StatsDashboard(
      season: season,
      teamsById: teamsById,
      standings: standings,
      teamStatsById: teamStatsById,
      leadersByStat: leadersByStat,
      warnings: warnings,
    );
  }

  List<Game> _sortGames(List<Game> games) {
    final List<Game> sorted = List<Game>.from(games);
    sorted.sort((Game a, Game b) {
      final int byDate = b.parsedDate.compareTo(a.parsedDate);
      if (byDate != 0) {
        return byDate;
      }

      final int byPriority =
          _priorityForGame(a).compareTo(_priorityForGame(b));
      if (byPriority != 0) {
        return byPriority;
      }

      return a.homeTeam.fullName.compareTo(b.homeTeam.fullName);
    });
    return sorted;
  }

  int _priorityForGame(Game game) {
    if (game.isLive) {
      return 0;
    }
    if (game.isScheduled) {
      return 1;
    }
    if (game.isFinal) {
      return 2;
    }
    return 3;
  }

  String _labelForStat(String statType) {
    switch (statType) {
      case 'pts':
        return 'Points';
      case 'reb':
        return 'Rebounds';
      case 'ast':
        return 'Assists';
      case 'stl':
        return 'Steals';
      case 'blk':
        return 'Blocks';
      default:
        return statType.toUpperCase();
    }
  }
}
