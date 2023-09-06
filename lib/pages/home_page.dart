import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(1023, 20, 68, 144),
        title: Text(
          "NBA",
          style: GoogleFonts.bebasNeue(
            fontSize: 30,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout), onPressed: () => signOut()),
        ],
      ),
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
      bottomNavigationBar: Container(
        color: const Color.fromARGB(1023, 20, 68, 144),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GNav(
            backgroundColor: const Color.fromARGB(1023, 20, 68, 144),
            gap: 8,
            onTabChange: (value) {},
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            tabs: [
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.newspaper,
                backgroundColor: Colors.red,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "news",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.scoreboard_outlined,
                backgroundColor: Colors.red,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "score",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.stacked_bar_chart_rounded,
                backgroundColor: Colors.red,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "stats",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.account_box_rounded,
                backgroundColor: Colors.red,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "profile",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
