import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_jordan/services/nba_api_service.dart';

void main() {
  test('NbaApiService.fetchTeams parses a successful response', () async {
    final NbaApiService service = NbaApiService(
      apiKey: 'test-key',
      client: MockClient((http.Request request) async {
        expect(request.url.host, 'api.balldontlie.io');
        expect(request.url.path, '/v1/teams');
        expect(request.headers['Authorization'], 'test-key');

        return http.Response('''
          {
            "data": [
              {
                "id": 14,
                "abbreviation": "LAL",
                "city": "Los Angeles",
                "conference": "West",
                "division": "Pacific",
                "full_name": "Los Angeles Lakers",
                "name": "Lakers"
              }
            ]
          }
        ''', 200);
      }),
    );

    final teams = await service.fetchTeams();

    expect(teams, hasLength(1));
    expect(teams.first.fullName, 'Los Angeles Lakers');
  });

  test('NbaApiService.fetchGames parses a successful response', () async {
    final NbaApiService service = NbaApiService(
      apiKey: 'test-key',
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/v1/games');

        return http.Response('''
          {
            "data": [
              {
                "id": 1,
                "date": "2026-03-17T10:00:00Z",
                "home_team_score": 120,
                "visitor_team_score": 115,
                "season": 2026,
                "period": 4,
                "status": "Final",
                "time": "",
                "postseason": false,
                "home_team": {
                  "id": 14,
                  "abbreviation": "LAL",
                  "city": "Los Angeles",
                  "conference": "West",
                  "division": "Pacific",
                  "full_name": "Los Angeles Lakers",
                  "name": "Lakers"
                },
                "visitor_team": {
                  "id": 2,
                  "abbreviation": "BOS",
                  "city": "Boston",
                  "conference": "East",
                  "division": "Atlantic",
                  "full_name": "Boston Celtics",
                  "name": "Celtics"
                }
              }
            ]
          }
        ''', 200);
      }),
    );

    final games = await service.fetchGames();

    expect(games, hasLength(1));
    expect(games.first.status, 'Final');
    expect(games.first.homeTeam.fullName, 'Los Angeles Lakers');
  });

  test('NbaApiService throws when API key is missing', () async {
    final NbaApiService service = NbaApiService(
      apiKey: '',
      client: MockClient((http.Request request) async {
        fail('Client should not be called when the API key is missing.');
      }),
    );

    expect(() => service.fetchTeams(), throwsA(isA<NbaApiException>()));
  });
}
