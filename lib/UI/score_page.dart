import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:http/http.dart' as http;

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  List<Game> games = [];

  Future getGames() async {
    var response = await http.get(Uri.https("balldontlie.io", "api/v1/game/"));
    var jsonData = jsonDecode(response.body);

    for (var eachTeam in jsonData['data']) {
      final team = Game(
        id: eachTeam['id'],
        date: eachTeam['date'],
        homeTeam: eachTeam['home_team'],
        period: eachTeam['period'],
        homeTeamScore: eachTeam['id'],
        time: eachTeam['id'],
        postseason: eachTeam['id'],
        season: eachTeam['id'],
        status: eachTeam['id'],
        visitorTeam: eachTeam['id'],
        visitorTeamScore: eachTeam['id'],
      );
      games.add(team);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getGames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      "${games[index].id}\n${games[index].date} VS ${games[index].period}"),
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
