import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_jordan/model/Teams.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  List<Team> teams = [];

  Future getTeams() async {
    var response = await http.get(Uri.https("balldontlie.io", "api/v1/teams"));
    var jsonData = jsonDecode(response.body);

    for (var eachTeam in jsonData['data']) {
      final team =
          Team(abbriviaton: eachTeam['abbreviation'], city: eachTeam['city']);
      teams.add(team);
    }
  }

  Future getPlayers() async {}

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
                        "${teams[index].abbriviaton}, ${teams[index].city}"),
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
