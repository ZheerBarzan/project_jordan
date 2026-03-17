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
                "postponed": false,
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

  test('NbaApiService.fetchStandings parses standings data', () async {
    final NbaApiService service = NbaApiService(
      apiKey: 'test-key',
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/v1/standings');
        expect(request.url.queryParameters['season'], '2025');

        return http.Response('''
          {
            "data": [
              {
                "conference_record": "42-18",
                "conference_rank": 1,
                "division_record": "12-4",
                "division_rank": 1,
                "wins": 52,
                "losses": 20,
                "home_record": "28-8",
                "road_record": "24-12",
                "season": 2025,
                "team": {
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

    final standings = await service.fetchStandings(season: 2025);

    expect(standings, hasLength(1));
    expect(standings.first.team.fullName, 'Boston Celtics');
    expect(standings.first.conferenceRank, 1);
  });

  test('NbaApiService.fetchTeamSeasonStats parses season averages', () async {
    final NbaApiService service = NbaApiService(
      apiKey: 'test-key',
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/nba/v1/team_season_averages/general');
        expect(request.url.queryParameters['season'], '2025');

        return http.Response('''
          {
            "data": [
              {
                "season": 2025,
                "season_type": "regular",
                "team": {
                  "id": 14,
                  "abbreviation": "LAL",
                  "city": "Los Angeles",
                  "conference": "West",
                  "division": "Pacific",
                  "full_name": "Los Angeles Lakers",
                  "name": "Lakers"
                },
                "stats": {
                  "w": 48,
                  "l": 24,
                  "gp": 72,
                  "pts": 118.2,
                  "reb": 45.1,
                  "ast": 27.9,
                  "stl": 8.1,
                  "blk": 5.6,
                  "fg_pct": 48.3,
                  "fg3_pct": 37.9,
                  "plus_minus": 6.1
                }
              }
            ]
          }
        ''', 200);
      }),
    );

    final stats = await service.fetchTeamSeasonStats(season: 2025);

    expect(stats, hasLength(1));
    expect(stats.first.points, 118.2);
    expect(stats.first.team.abbreviation, 'LAL');
  });

  test('NbaApiService.fetchLeaders parses player leader data', () async {
    final NbaApiService service = NbaApiService(
      apiKey: 'test-key',
      client: MockClient((http.Request request) async {
        expect(request.url.path, '/v1/leaders');
        expect(request.url.queryParameters['stat_type'], 'pts');

        return http.Response('''
          {
            "data": [
              {
                "rank": 1,
                "value": 32.1,
                "season": 2025,
                "games_played": 68,
                "stat_type": "pts",
                "player": {
                  "id": 246,
                  "first_name": "Stephen",
                  "last_name": "Curry",
                  "position": "G",
                  "team_id": 10
                }
              }
            ]
          }
        ''', 200);
      }),
    );

    final leaders = await service.fetchLeaders(season: 2025, statType: 'pts');

    expect(leaders, hasLength(1));
    expect(leaders.first.player.fullName, 'Stephen Curry');
    expect(leaders.first.value, 32.1);
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
