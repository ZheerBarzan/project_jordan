import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:project_jordan/repositories/scoreboard_content_repository.dart';
import 'package:project_jordan/services/asset_fixture_loader.dart';

void main() {
  test(
    'ScoreboardContentRepository loads branding and builds enriched detail',
    () async {
      final ScoreboardContentRepository repository =
          ScoreboardContentRepository(
            fixtureLoader: AssetFixtureLoader(
              loadString: (String path) async {
                switch (path) {
                  case 'assets/data/team_branding.json':
                    return _teamBrandingJson;
                  case 'assets/data/game_details.json':
                    return _gameDetailsJson;
                  default:
                    throw ArgumentError('Unexpected asset path: $path');
                }
              },
            ),
          );

      final branding = await repository.loadTeamBranding();
      final details = await repository.loadGameDetailEnrichment();
      final gameDetail = repository.buildGameDetail(_game(), details);

      expect(branding['GSW']?.logoAsset, 'images/nba/GSW.png');
      expect(gameDetail.arena, 'Chase Center');
      expect(gameDetail.hasSummary, isTrue);
      expect(gameDetail.hasLineScore, isTrue);
    },
  );

  test(
    'ScoreboardContentRepository returns base detail when enrichment is absent',
    () async {
      final ScoreboardContentRepository repository =
          ScoreboardContentRepository(
            fixtureLoader: AssetFixtureLoader(
              loadString: (String path) async {
                switch (path) {
                  case 'assets/data/team_branding.json':
                    return _teamBrandingJson;
                  case 'assets/data/game_details.json':
                    return '{}';
                  default:
                    throw ArgumentError('Unexpected asset path: $path');
                }
              },
            ),
          );

      final details = await repository.loadGameDetailEnrichment();
      final gameDetail = repository.buildGameDetail(_game(), details);

      expect(gameDetail.hasEnrichment, isFalse);
      expect(gameDetail.game.homeTeam.fullName, 'Golden State Warriors');
    },
  );
}

Game _game() {
  return Game(
    id: 11,
    date: '2026-03-18T02:00:00Z',
    homeTeamScore: 103,
    visitorTeamScore: 109,
    season: 2025,
    period: 3,
    status: '3rd Qtr',
    time: '9:00 PM ET',
    postseason: false,
    postponed: false,
    homeTeam: Team(
      id: 10,
      abbreviation: 'GSW',
      city: 'Golden State',
      conference: 'West',
      division: 'Pacific',
      fullName: 'Golden State Warriors',
      name: 'Warriors',
    ),
    visitorTeam: Team(
      id: 25,
      abbreviation: 'OKC',
      city: 'Oklahoma City',
      conference: 'West',
      division: 'Northwest',
      fullName: 'Oklahoma City Thunder',
      name: 'Thunder',
    ),
  );
}

const String _teamBrandingJson = '''
{
  "GSW": {"logoAsset": "images/nba/GSW.png", "primaryColor": "#1D428A"},
  "OKC": {"logoAsset": "images/nba/OKC.png", "primaryColor": "#007AC1"}
}
''';

const String _gameDetailsJson = '''
{
  "11": {
    "arena": "Chase Center",
    "location": "San Francisco, California",
    "headline": "Thunder pressure Golden State in a live matchup",
    "summary": "Oklahoma City has pushed the pace and kept Golden State scrambling in transition.",
    "notes": ["Thunder lead the transition scoring battle."],
    "homeLineScores": [31, 33, 39],
    "visitorLineScores": [35, 36, 38]
  }
}
''';
