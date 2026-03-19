import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/model/teams.dart';

class NbaApiService {
  NbaApiService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? _defaultApiKey;

  static const String _defaultApiKey = String.fromEnvironment(
    'BALLDONTLIE_API_KEY',
  );
  static const String _authority = 'api.balldontlie.io';

  final http.Client _client;
  final String _apiKey;

  Future<List<Team>> fetchTeams() async {
    final Map<String, dynamic> json = await _getJson(
      '/v1/teams',
      queryParameters: <String, String>{'per_page': '100'},
    );
    final List<dynamic> teamsJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return teamsJson
        .map((dynamic item) => Team.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Game>> fetchGames({
    List<DateTime>? dates,
    DateTime? startDate,
    DateTime? endDate,
    int perPage = 100,
  }) async {
    final Map<String, String> queryParameters = <String, String>{
      'per_page': '$perPage',
      if (startDate != null) 'start_date': _formatDate(startDate),
      if (endDate != null) 'end_date': _formatDate(endDate),
    };
    final Map<String, List<String>> listQueryParameters =
        <String, List<String>>{
          if (dates != null && dates.isNotEmpty)
            'dates[]': dates.map(_formatDate).toList(),
        };

    final Map<String, dynamic> json = await _getJson(
      '/v1/games',
      queryParameters: queryParameters,
      listQueryParameters: listQueryParameters,
    );
    final List<dynamic> gamesJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return gamesJson
        .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TeamStanding>> fetchStandings({required int season}) async {
    final Map<String, dynamic> json = await _getJson(
      '/v1/standings',
      queryParameters: <String, String>{'season': '$season'},
    );
    final List<dynamic> standingsJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return standingsJson
        .map(
          (dynamic item) => TeamStanding.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<TeamSeasonStats>> fetchTeamSeasonStats({
    required int season,
  }) async {
    final Map<String, dynamic> json = await _getJson(
      '/nba/v1/team_season_averages/general',
      queryParameters: <String, String>{
        'season': '$season',
        'season_type': 'regular',
        'type': 'base',
        'per_page': '100',
      },
    );
    final List<dynamic> statsJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return statsJson
        .map(
          (dynamic item) =>
              TeamSeasonStats.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<PlayerLeader>> fetchLeaders({
    required int season,
    required String statType,
  }) async {
    final Map<String, dynamic> json = await _getJson(
      '/v1/leaders',
      queryParameters: <String, String>{
        'season': '$season',
        'stat_type': statType,
      },
    );
    final List<dynamic> leadersJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return leadersJson
        .map(
          (dynamic item) => PlayerLeader.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
    Map<String, List<String>> listQueryParameters =
        const <String, List<String>>{},
  }) async {
    if (_apiKey.isEmpty) {
      throw const NbaApiException(
        'BALLDONTLIE_API_KEY is missing from this build. Stop the app and run it again with --dart-define-from-file=.dart_define.local.json or --dart-define=BALLDONTLIE_API_KEY=your_api_key.',
      );
    }

    final Uri uri = _buildUri(
      path,
      queryParameters: queryParameters,
      listQueryParameters: listQueryParameters,
    );
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Authorization': _apiKey},
    );
    final Map<String, dynamic> json = _decodeJson(response.body);

    if (response.statusCode == 200) {
      return json;
    }

    final String message =
        json['message'] as String? ??
        json['error'] as String? ??
        'Failed to load NBA data.';
    throw NbaApiException(message);
  }

  Uri _buildUri(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
    Map<String, List<String>> listQueryParameters =
        const <String, List<String>>{},
  }) {
    final List<String> queryParts = <String>[];

    for (final MapEntry<String, String> entry in queryParameters.entries) {
      queryParts.add(
        '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      );
    }

    for (final MapEntry<String, List<String>> entry
        in listQueryParameters.entries) {
      for (final String value in entry.value) {
        queryParts.add(
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}',
        );
      }
    }

    final String query = queryParts.join('&');
    return Uri.parse(
      'https://$_authority$path${query.isEmpty ? '' : '?$query'}',
    );
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{'message': body};
    }
  }

  String _formatDate(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final String month = normalized.month.toString().padLeft(2, '0');
    final String day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

class NbaApiException implements Exception {
  const NbaApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
