import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/model/teams.dart';

void main() {
  test('Team.fromJson maps team payload fields', () {
    final Team team = Team.fromJson(<String, dynamic>{
      'id': 14,
      'abbreviation': 'LAL',
      'city': 'Los Angeles',
      'conference': 'West',
      'division': 'Pacific',
      'full_name': 'Los Angeles Lakers',
      'name': 'Lakers',
    });

    expect(team.id, 14);
    expect(team.abbreviation, 'LAL');
    expect(team.city, 'Los Angeles');
    expect(team.conference, 'West');
    expect(team.division, 'Pacific');
    expect(team.fullName, 'Los Angeles Lakers');
    expect(team.name, 'Lakers');
  });
}
