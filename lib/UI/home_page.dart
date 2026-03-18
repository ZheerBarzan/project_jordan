import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:project_jordan/UI/news_page.dart';
import 'package:project_jordan/UI/profile_page.dart';
import 'package:project_jordan/UI/score_page.dart';
import 'package:project_jordan/UI/stats_page.dart';
import 'package:project_jordan/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  late final List<Widget> pages = <Widget>[
    NewsPage(),
    ScorePage(),
    StatsPage(),
    const ProfilePage(),
  ];

  void goToPages(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[AppTheme.nbaBlue, AppTheme.courtBlue],
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('images/x.png', height: 50),
            const SizedBox(width: 10),
            Text(
              "NBA",
              style: GoogleFonts.bebasNeue(
                fontSize: 34,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[AppTheme.courtBlue, AppTheme.nbaBlue],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GNav(
            selectedIndex: currentIndex,
            backgroundColor: Colors.transparent,
            gap: 8,
            onTabChange: (index) => goToPages(index),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            tabs: [
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.newspaper,
                backgroundColor: AppTheme.accentRed,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "news",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.scoreboard_outlined,
                backgroundColor: AppTheme.accentRed,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "score",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.stacked_bar_chart_rounded,
                backgroundColor: AppTheme.accentRed,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "stats",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              GButton(
                borderRadius: BorderRadius.circular(25),
                icon: Icons.account_box_rounded,
                backgroundColor: AppTheme.accentRed,
                iconActiveColor: Colors.white,
                iconColor: Colors.white,
                text: "profile",
                textStyle: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      extendBody: true,
    );
  }
}
