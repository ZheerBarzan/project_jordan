import 'package:flutter/foundation.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/stats_dashboard.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:project_jordan/repositories/fallback_aware_repository.dart';
import 'package:project_jordan/services/asset_fixture_loader.dart';
import 'package:project_jordan/services/nba_api_service.dart';

abstract class BasketballDataRepository {
  Future<List<Game>> fetchGamesForDate(DateTime date);

  Future<List<Game>> fetchRecentGames({int days});

  Future<StatsDashboard> fetchStatsDashboard({required int season});
}

class BasketballRepository
    implements BasketballDataRepository, FallbackAwareRepository {
  BasketballRepository({
    NbaApiService? service,
    AssetFixtureLoader? fixtureLoader,
  }) : _service = service ?? NbaApiService(),
       _fixtureLoader = fixtureLoader ?? AssetFixtureLoader();

  static const List<String> defaultLeaderStats = <String>[
    'pts',
    'reb',
    'ast',
    'stl',
    'blk',
  ];
  static const String _fallbackAssetPath = 'assets/data/fallback_games.json';

  final NbaApiService _service;
  final AssetFixtureLoader _fixtureLoader;
  final ValueNotifier<bool> _isUsingFallbackData = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isUsingFallbackData => _isUsingFallbackData;

  @override
  Future<List<Game>> fetchGamesForDate(DateTime date) async {
    _isUsingFallbackData.value = false;

    try {
      final List<Game> games = await _service.fetchGames(
        dates: <DateTime>[date],
      );
      return _sortGames(games);
    } catch (_) {
      final List<Game> fallbackGames = await _loadFallbackGamesForDate(date);
      _isUsingFallbackData.value = true;
      return _sortGames(fallbackGames);
    }
  }

  @override
  Future<List<Game>> fetchRecentGames({int days = 4}) async {
    _isUsingFallbackData.value = false;

    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(Duration(days: days - 1));

    try {
      final List<Game> games = await _service.fetchGames(
        startDate: startDate,
        endDate: today,
      );
      return _sortGames(games);
    } catch (_) {
      final List<Game> fallbackGames = await _loadRecentFallbackGames(
        days: days,
      );
      _isUsingFallbackData.value = true;
      return _sortGames(fallbackGames);
    }
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
      final List<TeamSeasonStats> teamStats = await _service
          .fetchTeamSeasonStats(season: season);
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
          warnings.add(
            '${_labelForStat(statType)} leaders unavailable: $error',
          );
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

      final int byPriority = _priorityForGame(a).compareTo(_priorityForGame(b));
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

  Future<List<Game>> _loadFallbackGamesForDate(DateTime date) async {
    final List<Map<String, dynamic>> fixtures = await _fixtureLoader
        .loadJsonList(_fallbackAssetPath);

    return fixtures
        .map(
          (Map<String, dynamic> json) =>
              _gameFromFixture(json, targetDate: date),
        )
        .toList();
  }

  Future<List<Game>> _loadRecentFallbackGames({required int days}) async {
    final List<Map<String, dynamic>> fixtures = await _fixtureLoader
        .loadJsonList(_fallbackAssetPath);
    final DateTime today = _normalizedDate(DateTime.now());

    return fixtures.map((Map<String, dynamic> json) {
      final int offset = (json['fallback_day_offset'] as num?)?.toInt() ?? 0;
      final int clampedOffset = offset.clamp(0, days - 1);
      final DateTime targetDate = today.subtract(Duration(days: clampedOffset));
      return _gameFromFixture(json, targetDate: targetDate);
    }).toList();
  }

  Game _gameFromFixture(
    Map<String, dynamic> json, {
    required DateTime targetDate,
  }) {
    final Game game = Game.fromJson(json);
    final DateTime templateDate =
        DateTime.tryParse(game.date)?.toUtc() ??
        DateTime.utc(targetDate.year, targetDate.month, targetDate.day, 19);
    final DateTime normalizedTargetDate = _normalizedDate(targetDate);
    final DateTime today = _normalizedDate(DateTime.now());
    final bool isFutureDate = normalizedTargetDate.isAfter(today);
    final bool isPastDate = normalizedTargetDate.isBefore(today);
    final DateTime adjustedDate = DateTime.utc(
      normalizedTargetDate.year,
      normalizedTargetDate.month,
      normalizedTargetDate.day,
      templateDate.hour,
      templateDate.minute,
    );

    final String status = isFutureDate
        ? (game.time.isNotEmpty ? game.time : '7:30 PM ET')
        : (isPastDate && game.isLive ? 'Final' : game.status);
    final int homeTeamScore = isFutureDate ? 0 : game.homeTeamScore;
    final int visitorTeamScore = isFutureDate ? 0 : game.visitorTeamScore;

    return Game(
      id: game.id,
      date: adjustedDate.toIso8601String(),
      homeTeamScore: homeTeamScore,
      visitorTeamScore: visitorTeamScore,
      season: normalizedTargetDate.month >= 10
          ? normalizedTargetDate.year
          : normalizedTargetDate.year - 1,
      period: isFutureDate ? 0 : game.period,
      status: status,
      time: game.time,
      postseason: game.postseason,
      postponed: isFutureDate ? false : game.postponed,
      homeTeam: game.homeTeam,
      visitorTeam: game.visitorTeam,
    );
  }

  DateTime _normalizedDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
