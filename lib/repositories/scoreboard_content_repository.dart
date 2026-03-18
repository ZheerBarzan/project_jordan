import 'package:project_jordan/model/game_detail.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/team_branding.dart';
import 'package:project_jordan/services/asset_fixture_loader.dart';

class ScoreboardContentRepository {
  ScoreboardContentRepository({AssetFixtureLoader? fixtureLoader})
    : _fixtureLoader = fixtureLoader ?? AssetFixtureLoader();

  static const String _teamBrandingAssetPath = 'assets/data/team_branding.json';
  static const String _gameDetailsAssetPath = 'assets/data/game_details.json';

  final AssetFixtureLoader _fixtureLoader;

  Future<Map<String, TeamBranding>> loadTeamBranding() async {
    final Map<String, Map<String, dynamic>> json = await _fixtureLoader
        .loadJsonObjectMap(_teamBrandingAssetPath);

    return json.map(
      (String key, Map<String, dynamic> value) => MapEntry<String, TeamBranding>(
        key.toUpperCase(),
        TeamBranding.fromJson(key, value),
      ),
    );
  }

  Future<Map<int, Map<String, dynamic>>> loadGameDetailEnrichment() async {
    final Map<String, Map<String, dynamic>> json = await _fixtureLoader
        .loadJsonObjectMap(_gameDetailsAssetPath);

    return json.map(
      (String key, Map<String, dynamic> value) =>
          MapEntry<int, Map<String, dynamic>>(int.parse(key), value),
    );
  }

  GameDetail buildGameDetail(
    Game game,
    Map<int, Map<String, dynamic>> enrichmentByGameId,
  ) {
    return GameDetail.fromGame(
      game,
      enrichment: enrichmentByGameId[game.id],
    );
  }
}
