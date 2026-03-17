import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/model/game_model.dart';

void main() {
  test('Game.fromJson maps nested game and team payload fields', () {
    final Game game = Game.fromJson(<String, dynamic>{
      'id': 1,
      'date': '2026-03-17T10:00:00Z',
      'home_team_score': 120,
      'visitor_team_score': 115,
      'season': 2026,
      'period': 4,
      'status': 'Final',
      'time': '',
      'postseason': false,
      'home_team': <String, dynamic>{
        'id': 14,
        'abbreviation': 'LAL',
        'city': 'Los Angeles',
        'conference': 'West',
        'division': 'Pacific',
        'full_name': 'Los Angeles Lakers',
        'name': 'Lakers',
      },
      'visitor_team': <String, dynamic>{
        'id': 2,
        'abbreviation': 'BOS',
        'city': 'Boston',
        'conference': 'East',
        'division': 'Atlantic',
        'full_name': 'Boston Celtics',
        'name': 'Celtics',
      },
    });

    expect(game.id, 1);
    expect(game.homeTeam.fullName, 'Los Angeles Lakers');
    expect(game.visitorTeam.fullName, 'Boston Celtics');
    expect(game.homeTeamScore, 120);
    expect(game.visitorTeamScore, 115);
    expect(game.status, 'Final');
  });
}
