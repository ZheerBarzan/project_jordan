import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:project_jordan/UI/news_page.dart';
import 'package:project_jordan/UI/profile_page.dart';
import 'package:project_jordan/UI/score_page.dart';
import 'package:project_jordan/UI/stats_page.dart';
import 'package:project_jordan/components/scroll_chrome.dart';
import 'package:project_jordan/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.pagesBuilder});

  final List<Widget> Function(
    ChromeVisibilityChanged onChromeVisibilityChanged,
  )?
  pagesBuilder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _chromeHeight = 84;

  int currentIndex = 0;
  bool _isTopChromeVisible = true;

  late final List<Widget> pages =
      widget.pagesBuilder?.call(_handleChromeVisibility) ??
      <Widget>[
        NewsPage(onChromeVisibilityChanged: _handleChromeVisibility),
        ScorePage(onChromeVisibilityChanged: _handleChromeVisibility),
        StatsPage(onChromeVisibilityChanged: _handleChromeVisibility),
        const ProfilePage(),
      ];

  void goToPages(int index) {
    setState(() {
      currentIndex = index;
      _isTopChromeVisible = true;
    });
  }

  void _handleChromeVisibility(bool isVisible) {
    if (!mounted || currentIndex == 3 || _isTopChromeVisible == isVisible) {
      return;
    }

    setState(() {
      _isTopChromeVisible = isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppTheme.softBackground,
      body: Column(
        children: <Widget>[
          SizedBox(height: topInset),
          AnimatedContainer(
            key: const Key('home-top-chrome-shell'),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: _isTopChromeVisible ? _chromeHeight : 0,
            child: const ClipRect(child: _HomeTopChrome()),
          ),
          Expanded(
            child: IndexedStack(index: currentIndex, children: pages),
          ),
        ],
      ),
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
            onTabChange: (int index) => goToPages(index),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            tabs: <GButton>[
              _buildNavButton(icon: Icons.newspaper, text: 'news'),
              _buildNavButton(icon: Icons.scoreboard_outlined, text: 'score'),
              _buildNavButton(
                icon: Icons.stacked_bar_chart_rounded,
                text: 'stats',
              ),
              _buildNavButton(icon: Icons.account_box_rounded, text: 'profile'),
            ],
          ),
        ),
      ),
      extendBody: true,
    );
  }

  GButton _buildNavButton({required IconData icon, required String text}) {
    return GButton(
      borderRadius: BorderRadius.circular(25),
      icon: icon,
      backgroundColor: AppTheme.accentRed,
      iconActiveColor: Colors.white,
      iconColor: Colors.white,
      text: text,
      textStyle: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
    );
  }
}

class _HomeTopChrome extends StatelessWidget {
  const _HomeTopChrome();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppTheme.nbaBlue, AppTheme.courtBlue],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('images/x.png', height: 50),
            const SizedBox(width: 10),
            Text(
              'NBA',
              style: GoogleFonts.bebasNeue(
                fontSize: 34,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
