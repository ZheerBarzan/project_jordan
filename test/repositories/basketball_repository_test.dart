import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_jordan/repositories/basketball_repository.dart';
import 'package:project_jordan/services/asset_fixture_loader.dart';
import 'package:project_jordan/services/nba_api_service.dart';

void main() {
  test('BasketballRepository falls back when API key is missing', () async {
    final BasketballRepository repository = BasketballRepository(
      service: NbaApiService(apiKey: ''),
      fixtureLoader: AssetFixtureLoader(
        loadString: (_) async => _fallbackGamesJson,
      ),
    );

    final games = await repository.fetchGamesForDate(
      DateTime.parse('2026-03-18T12:00:00Z'),
    );

    expect(games, isNotEmpty);
    expect(repository.isUsingFallbackData.value, isTrue);
    expect(games.first.homeTeam.fullName, isNotEmpty);
  });

  test(
    'BasketballRepository falls back when live fetch returns an error',
    () async {
      final BasketballRepository repository = BasketballRepository(
        service: NbaApiService(
          apiKey: 'live-key',
          client: MockClient((http.Request _) async {
            return http.Response('{"message":"Forbidden"}', 403);
          }),
        ),
        fixtureLoader: AssetFixtureLoader(
          loadString: (_) async => _fallbackGamesJson,
        ),
      );

      final games = await repository.fetchRecentGames(days: 4);

      expect(games, isNotEmpty);
      expect(repository.isUsingFallbackData.value, isTrue);
      expect(
        games.any((game) => game.homeTeam.fullName == 'Los Angeles Lakers'),
        isTrue,
      );
    },
  );
}

const String _fallbackGamesJson = '''
[
  {
    "id": 101,
    "date": "2026-03-18T00:30:00Z",
    "home_team_score": 118,
    "visitor_team_score": 112,
    "season": 2025,
    "period": 4,
    "status": "Final",
    "time": "7:30 PM ET",
    "postseason": false,
    "postponed": false,
    "fallback_day_offset": 0,
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
  },
  {
    "id": 102,
    "date": "2026-03-18T02:00:00Z",
    "home_team_score": 99,
    "visitor_team_score": 104,
    "season": 2025,
    "period": 3,
    "status": "3rd Qtr",
    "time": "9:00 PM ET",
    "postseason": false,
    "postponed": false,
    "fallback_day_offset": 0,
    "home_team": {
      "id": 10,
      "abbreviation": "GSW",
      "city": "Golden State",
      "conference": "West",
      "division": "Pacific",
      "full_name": "Golden State Warriors",
      "name": "Warriors"
    },
    "visitor_team": {
      "id": 25,
      "abbreviation": "OKC",
      "city": "Oklahoma City",
      "conference": "West",
      "division": "Northwest",
      "full_name": "Oklahoma City Thunder",
      "name": "Thunder"
    }
  }
]
''';
