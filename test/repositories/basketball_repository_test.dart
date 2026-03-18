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
    'BasketballRepository exposes upcoming fallback games without finals',
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

      final games = await repository.fetchUpcomingGames(days: 7);

      expect(games, isNotEmpty);
      expect(repository.isUsingFallbackData.value, isTrue);
      expect(games.any((game) => game.isFinal), isFalse);
      expect(
        games.any((game) => game.homeTeam.fullName == 'Golden State Warriors'),
        isTrue,
      );
    },
  );

  test(
    'BasketballRepository exposes previous fallback games without scheduled games',
    () async {
      final BasketballRepository repository = BasketballRepository(
        service: NbaApiService(apiKey: ''),
        fixtureLoader: AssetFixtureLoader(
          loadString: (_) async => _fallbackGamesJson,
        ),
      );

      final games = await repository.fetchPreviousGames(days: 14);

      expect(games, isNotEmpty);
      expect(games.every((game) => game.isFinal || game.postponed), isTrue);
      expect(
        games.any((game) => game.homeTeam.fullName == 'Denver Nuggets'),
        isFalse,
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
    "fallback_relative_day_offset": 0,
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
    "fallback_relative_day_offset": 0,
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
  },
  {
    "id": 103,
    "date": "2026-03-17T00:00:00Z",
    "home_team_score": 121,
    "visitor_team_score": 117,
    "season": 2025,
    "period": 4,
    "status": "Final",
    "time": "7:00 PM ET",
    "postseason": false,
    "postponed": false,
    "fallback_relative_day_offset": -1,
    "home_team": {
      "id": 5,
      "abbreviation": "NYK",
      "city": "New York",
      "conference": "East",
      "division": "Atlantic",
      "full_name": "New York Knicks",
      "name": "Knicks"
    },
    "visitor_team": {
      "id": 15,
      "abbreviation": "MIA",
      "city": "Miami",
      "conference": "East",
      "division": "Southeast",
      "full_name": "Miami Heat",
      "name": "Heat"
    }
  },
  {
    "id": 106,
    "date": "2026-03-19T00:30:00Z",
    "home_team_score": 0,
    "visitor_team_score": 0,
    "season": 2025,
    "period": 0,
    "status": "7:30 PM ET",
    "time": "7:30 PM ET",
    "postseason": false,
    "postponed": false,
    "fallback_relative_day_offset": 1,
    "home_team": {
      "id": 8,
      "abbreviation": "DEN",
      "city": "Denver",
      "conference": "West",
      "division": "Northwest",
      "full_name": "Denver Nuggets",
      "name": "Nuggets"
    },
    "visitor_team": {
      "id": 6,
      "abbreviation": "DAL",
      "city": "Dallas",
      "conference": "West",
      "division": "Southwest",
      "full_name": "Dallas Mavericks",
      "name": "Mavericks"
    }
  }
]
''';
