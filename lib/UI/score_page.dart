import 'package:flutter/material.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/services/nba_api_service.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final NbaApiService _nbaApiService = NbaApiService();
  late final Future<List<Game>> _futureGames;

  @override
  void initState() {
    super.initState();
    _futureGames = _nbaApiService.fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Game>>(
        future: _futureGames,
        builder: (BuildContext context, AsyncSnapshot<List<Game>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            final List<Game> games = snapshot.data!;
            return ListView.builder(
              itemCount: games.length,
              itemBuilder: (BuildContext context, int index) {
                final Game game = games[index];
                return ListTile(
                  title: Text(
                    '${game.homeTeam.fullName} ${game.homeTeamScore}'
                    '\n${game.visitorTeam.fullName} ${game.visitorTeamScore}'
                    '\n${game.status}',
                  ),
                  subtitle: Text(
                    'Season ${game.season} • Period ${game.period}',
                  ),
                );
              },
            );
          }
          return const Center(
            child: SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
