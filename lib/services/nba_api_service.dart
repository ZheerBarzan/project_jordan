import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_jordan/model/game_model.dart';
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
    final Map<String, dynamic> json = await _getJson('/v1/teams');
    final List<dynamic> teamsJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return teamsJson
        .map((dynamic item) => Team.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Game>> fetchGames() async {
    final Map<String, dynamic> json = await _getJson('/v1/games');
    final List<dynamic> gamesJson =
        json['data'] as List<dynamic>? ?? <dynamic>[];

    return gamesJson
        .map((dynamic item) => Game.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    if (_apiKey.isEmpty) {
      throw const NbaApiException(
        'BALLDONTLIE_API_KEY is missing. Configure it with --dart-define to load scores and teams.',
      );
    }

    final Uri uri = Uri.https(_authority, path);
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Authorization': _apiKey},
    );
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return json;
    }

    final String message =
        json['message'] as String? ??
        json['error'] as String? ??
        'Failed to load NBA data.';
    throw NbaApiException(message);
  }
}

class NbaApiException implements Exception {
  const NbaApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
