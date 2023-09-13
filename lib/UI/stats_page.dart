import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:http/http.dart' as http;

class StatPage extends StatefulWidget {
  const StatPage({super.key});

  @override
  State<StatPage> createState() => _StatPageState();
}

class _StatPageState extends State<StatPage> {
  List<Team> teams = [];

  Future getTeams() async {
    var response = await http.get(Uri.https("balldontlie.io", "api/v1/teams"));
    var jsonData = jsonDecode(response.body);

    for (var eachTeam in jsonData['data']) {
      final team = Team(
        abbriviaton: eachTeam['abbreviation'],
        city: eachTeam['city'],
        conference: eachTeam['conference'],
        division: eachTeam['division'],
        full_name: eachTeam['full_name'],
      );
      teams.add(team);
    }
  }

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
                    title: Text(
                        "${teams[index].abbriviaton}, ${teams[index].city} , ${teams[index].full_name}"),
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
