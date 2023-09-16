import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:http/http.dart' as http;

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List<Team> teams = [];

  Future getTeams() async {
    var response = await http.get(Uri.https("balldontlie.io", "api/v1/teams"));
    var jsonData = jsonDecode(response.body);

    for (var eachTeam in jsonData['data']) {
      final team = Team(
          id: eachTeam['id'],
          abbreviation: eachTeam['abbreviation'],
          city: eachTeam['city'],
          conference: eachTeam['conference'],
          division: eachTeam['division'],
          fullName: eachTeam['full_name'],
          name: eachTeam['name']);
      teams.add(team);
    }
  }

  Map<String, Image> nbaLogos = {
    "LAL": Image.asset('images/nba/LAL.png'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getTeams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
                itemCount: teams.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  return ListTile(
                    title: Row(
                      children: [
                        Image.asset(
                          'images/nba/LAL.png',
                          height: 20,
                          width: 20,
                        ),
                        Text(
                            "${teams[index].abbreviation}, ${teams[index].city} , ${teams[index].fullName}"),
                      ],
                    ),
                  );
                });
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
