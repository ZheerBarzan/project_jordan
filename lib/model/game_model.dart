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
  final bool postponed;
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
    required this.postponed,
    required this.homeTeam,
    required this.visitorTeam,
  });

  DateTime get parsedDate =>
      DateTime.tryParse(date)?.toLocal() ?? DateTime.now();

  bool get isLive =>
      status.contains('Qtr') ||
      status == 'Halftime' ||
      status == 'Overtime' ||
      status == 'End of Regulation';

  bool get isFinal => status == 'Final';

  bool get isScheduled => !isLive && !isFinal && !postponed;

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as int,
      date: (json['date'] ?? '').toString(),
      homeTeamScore: json['home_team_score'] as int? ?? 0,
      visitorTeamScore: json['visitor_team_score'] as int? ?? 0,
      season: json['season'] as int? ?? 0,
      period: json['period'] as int? ?? 0,
      status: (json['status'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      postseason: json['postseason'] as bool? ?? false,
      postponed: json['postponed'] as bool? ?? false,
      homeTeam: Team.fromJson(json['home_team']),
      visitorTeam: Team.fromJson(json['visitor_team']),
    );
  }
}
