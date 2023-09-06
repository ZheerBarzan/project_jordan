import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:project_jordan/model/Teams.dart';
import 'package:project_jordan/pages/news_page.dart';
import 'package:project_jordan/pages/profile_page.dart';
import 'package:project_jordan/pages/score_page.dart';
import 'package:project_jordan/pages/stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  int currentIndex = 0;

  List pages = [
    const NewsPage(),
    const ScorePage(),
    const StatPage(),
    const ProfilePage()
  ];

  void goToPages(index) {
    setState(() {
      currentIndex = index;
    });
  }

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
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        color: const Color.fromARGB(1023, 20, 68, 144),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GNav(
            backgroundColor: const Color.fromARGB(1023, 20, 68, 144),
            gap: 8,
            onTabChange: (index) => goToPages(index),
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
