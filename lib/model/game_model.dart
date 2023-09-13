import 'package:project_jordan/model/teams.dart';

class Game {
  final int id;
  final String date;
  final int homeTeamScore;
  final int visitorTeamScore;
  final int season;
  final int period;
  final String status;
  final String time;
  final bool postseason;
  final Team homeTeam;
  final Team visitorTeam;

  Game({
    required this.id,
    required this.date,
    required this.homeTeamScore,
    required this.visitorTeamScore,
    required this.season,
    required this.period,
    required this.status,
    required this.time,
    required this.postseason,
    required this.homeTeam,
    required this.visitorTeam,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      date: json['date'],
      homeTeamScore: json['home_team_score'],
      visitorTeamScore: json['visitor_team_score'],
      season: json['season'],
      period: json['period'],
      status: json['status'],
      time: json['time'],
      postseason: json['postseason'],
      homeTeam: Team.fromJson(json['home_team']),
      visitorTeam: Team.fromJson(json['visitor_team']),
    );
  }
}
