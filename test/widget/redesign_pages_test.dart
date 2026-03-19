import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/UI/article_reader_page.dart';
import 'package:project_jordan/UI/home_page.dart';
import 'package:project_jordan/UI/news_page.dart';
import 'package:project_jordan/UI/score_page.dart';
import 'package:project_jordan/UI/stats_page.dart';
import 'package:project_jordan/components/scroll_chrome.dart';
import 'package:project_jordan/components/team_logo_badge.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/model/player.dart';
import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/stats_dashboard.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:project_jordan/repositories/basketball_repository.dart';
import 'package:project_jordan/repositories/news_repository.dart';
import 'package:project_jordan/repositories/scoreboard_content_repository.dart';
import 'package:project_jordan/services/asset_fixture_loader.dart';
import 'package:project_jordan/services/news_provider.dart';
import 'package:project_jordan/services/nba_api_service.dart';
import 'package:project_jordan/theme/app_theme.dart';

void main() {
  testWidgets('NewsPage renders feed data and recovers after retry', (
    WidgetTester tester,
  ) async {
    int callCount = 0;
    final _FakeNewsRepository repository = _FakeNewsRepository(() async {
      callCount += 1;
      if (callCount == 1) {
        throw Exception('Primary news feed offline');
      }

      return _sampleArticles();
    });

    await tester.pumpWidget(
      _TestApp(home: NewsPage(repository: repository), wrapInScaffold: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('News feed unavailable'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Top headline'), findsOneWidget);
    expect(find.text('Bench unit update'), findsOneWidget);
    expect(find.text('Latest Coverage'), findsOneWidget);
  });

  testWidgets(
    'NewsPage switches layouts, removes card buttons, and opens article detail',
    (WidgetTester tester) async {
      final _FakeNewsRepository repository = _FakeNewsRepository(
        () async => _sampleArticles(),
      );

      await tester.pumpWidget(
        _TestApp(home: NewsPage(repository: repository), wrapInScaffold: true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('news-list')), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Copy Link'), findsNothing);

      await tester.tap(find.text('Grid'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('news-grid')), findsOneWidget);

      final Finder leadStoryFinder = find.byKey(
        ValueKey<String>('news-card-${_sampleArticles().first.dedupeKey}'),
      );
      await tester.ensureVisible(leadStoryFinder);
      await tester.tap(leadStoryFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Top headline'), findsWidgets);
      expect(find.text('Lead story content'), findsOneWidget);
      expect(
        find.byKey(const Key('article-reader-inline-message')),
        findsNothing,
      );
    },
  );

  testWidgets('NewsPage renders text cards with source and timestamp', (
    WidgetTester tester,
  ) async {
    final List<Article> articles = _sampleArticles();

    await tester.pumpWidget(
      _TestApp(
        home: NewsPage(repository: _FakeNewsRepository(() async => articles)),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Top headline'), findsOneWidget);
    expect(find.text('Bench unit update'), findsOneWidget);
    expect(find.text('Lead story summary'), findsOneWidget);
    expect(find.text('Secondary summary'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey<String>('news-meta-source-${articles.first.dedupeKey}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey<String>('news-meta-timestamp-${articles.first.dedupeKey}'),
      ),
      findsOneWidget,
    );
    expect(find.text('The Daily Wire'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('ArticleReaderPage shows placeholder image on broken image url', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        home: ArticleReaderPage(
          article: Article(
            title: 'Broken image story',
            description: 'Story summary',
            content: 'Story content',
            url: 'https://example.com/story',
            publishedAt: DateTime.parse('2026-03-17T12:00:00Z'),
            source: 'ESPN',
            urlToImage: 'https://broken.example.com/image.png',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('article-fallback-image-asset')),
      findsOneWidget,
    );
  });

  testWidgets(
    'ArticleReaderPage shows content note when full text is missing',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _TestApp(
          home: ArticleReaderPage(
            article: Article(
              title: 'No content story',
              description: 'Available summary only',
              url: 'https://example.com/story',
              publishedAt: DateTime.parse('2026-03-17T12:00:00Z'),
              source: 'ESPN',
              urlToImage: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('article-content-note')), findsOneWidget);
      expect(
        find.text(
          'Full article text is not available from this news feed payload.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('article-reader-inline-message')),
        findsNothing,
      );
    },
  );

  testWidgets('HomePage top chrome hides on scroll down and returns on up', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        home: HomePage(
          pagesBuilder: (ChromeVisibilityChanged onChromeVisibilityChanged) =>
              <Widget>[
                _ChromeTestPage(
                  onChromeVisibilityChanged: onChromeVisibilityChanged,
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('home-top-chrome-shell'))).height,
      greaterThan(0),
    );

    await tester.drag(
      find.byKey(const Key('chrome-test-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('home-top-chrome-shell'))).height,
      0,
    );

    await tester.drag(
      find.byKey(const Key('chrome-test-list')),
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('home-top-chrome-shell'))).height,
      greaterThan(0),
    );
  });

  testWidgets('ScorePage defaults to upcoming games and switches to previous', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[
        _game(
          id: 11,
          date: '2026-03-19T01:00:00Z',
          home: _team(14, 'LAL', 'Los Angeles Lakers', 'West'),
          visitor: _team(2, 'BOS', 'Boston Celtics', 'East'),
          status: '7:30 PM ET',
          homeTeamScore: 0,
          visitorTeamScore: 0,
        ),
      ],
      previousGames: <Game>[
        _game(
          id: 12,
          date: '2026-03-16T00:00:00Z',
          home: _team(5, 'NYK', 'New York Knicks', 'East'),
          visitor: _team(22, 'MIA', 'Miami Heat', 'East'),
        ),
      ],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: ScorePage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Los Angeles Lakers'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('New York Knicks'), findsOneWidget);
    expect(find.text('Los Angeles Lakers'), findsNothing);
  });

  testWidgets('ScorePage opens enriched game detail page from a score card', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[
        _game(
          id: 11,
          date: '2026-03-19T01:00:00Z',
          home: _team(10, 'GSW', 'Golden State Warriors', 'West'),
          visitor: _team(25, 'OKC', 'Oklahoma City Thunder', 'West'),
          status: '3rd Qtr',
          homeTeamScore: 103,
          visitorTeamScore: 109,
        ),
      ],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: ScorePage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    final Finder enrichedCard = find.byKey(
      const ValueKey<String>('score-card-11'),
    );
    await tester.ensureVisible(enrichedCard);
    tester.widget<InkWell>(enrichedCard).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Game Detail'), findsOneWidget);
    expect(find.text('Chase Center'), findsOneWidget);
    expect(find.text('Line Score'), findsOneWidget);
    expect(find.text('Matchup Summary'), findsOneWidget);
  });

  testWidgets('Game detail page still renders core info without enrichment', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[
        _game(
          id: 12,
          date: '2026-03-19T01:00:00Z',
          home: _team(14, 'LAL', 'Los Angeles Lakers', 'West'),
          visitor: _team(2, 'BOS', 'Boston Celtics', 'East'),
          status: '7:30 PM ET',
          homeTeamScore: 0,
          visitorTeamScore: 0,
        ),
      ],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: ScorePage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    final Finder baseCard = find.byKey(const ValueKey<String>('score-card-12'));
    await tester.ensureVisible(baseCard);
    tester.widget<InkWell>(baseCard).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Game Detail'), findsOneWidget);
    expect(find.text('Los Angeles Lakers'), findsOneWidget);
    expect(find.text('Boston Celtics'), findsOneWidget);
    expect(find.text('Matchup Summary'), findsNothing);
  });

  testWidgets('StatsPage defaults to standings and switches to leaders', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: StatsPage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-primary-tabs')), findsOneWidget);
    expect(find.byKey(const Key('stats-table-east')), findsOneWidget);

    await tester.tap(find.text('Leaders'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-featured-leaders')), findsOneWidget);
    expect(find.text('Points Leaders'), findsOneWidget);
    expect(find.text('Stephen Curry'), findsOneWidget);
  });

  testWidgets('StatsPage season selector reloads the dashboard', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );
    final int currentSeason = _currentNbaSeasonForTest();
    final int previousSeason = currentSeason - 1;

    await tester.pumpWidget(
      _TestApp(
        home: StatsPage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedStatsSeasons.last, currentSeason);

    await tester.tap(find.byKey(const Key('stats-season-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_seasonLabelForTest(previousSeason)).last);
    await tester.pumpAndSettle();

    expect(repository.requestedStatsSeasons, contains(previousSeason));
    expect(find.text(_seasonLabelForTest(previousSeason)), findsWidgets);
  });

  testWidgets('StatsPage uses the conference switcher on narrow layouts', (
    WidgetTester tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: StatsPage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-conference-switcher')), findsOneWidget);
    expect(find.byKey(const Key('stats-standing-row-BOS')), findsOneWidget);
    expect(find.byKey(const Key('stats-standing-row-OKC')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('stats-conference-switcher')),
    );
    final Finder westChip = find.descendant(
      of: find.byKey(const Key('stats-conference-switcher')),
      matching: find.text('West'),
    );
    await tester.ensureVisible(westChip);
    tester
        .widget<ChoiceChip>(
          find.ancestor(of: westChip, matching: find.byType(ChoiceChip)),
        )
        .onSelected!(true);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'West'))
          .selected,
      isTrue,
    );
    expect(find.byKey(const Key('stats-standing-row-OKC')), findsOneWidget);
  });

  testWidgets('StatsPage leader chips switch leaderboard categories', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: StatsPage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leaders'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-leader-stat-chips')), findsOneWidget);
    expect(find.text('Points Leaders'), findsOneWidget);
    expect(find.byKey(const Key('stats-leader-row-pts-4')), findsOneWidget);

    await tester.tap(find.text('AST'));
    await tester.pumpAndSettle();

    expect(find.text('Assist Leaders'), findsOneWidget);
    expect(find.text('LeBron James'), findsWidgets);
    expect(find.byKey(const Key('stats-leader-row-ast-1')), findsOneWidget);
  });

  testWidgets('StatsPage uses branding when available and falls back cleanly', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      upcomingGames: <Game>[],
      previousGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(
        home: StatsPage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      await _fakeScoreboardContentRepository().loadTeamBranding(),
      isNotEmpty,
    );
    expect(find.byType(TeamLogoBadge), findsWidgets);

    await tester.pumpWidget(
      _TestApp(
        home: StatsPage(
          repository: repository,
          contentRepository: _emptyBrandingContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stats-table-east')), findsOneWidget);
    expect(find.byType(TeamLogoBadge), findsWidgets);
    expect(await _emptyBrandingContentRepository().loadTeamBranding(), isEmpty);
  });

  testWidgets('NewsPage shows demo content without fallback banner', (
    WidgetTester tester,
  ) async {
    final NewsRepository repository = NewsRepository(
      providers: <NewsProvider>[
        _WidgetFakeProvider(
          name: 'NewsAPI',
          loader: () async =>
              throw const NewsProviderException('NEWSAPI_API_KEY is missing.'),
        ),
      ],
      fixtureLoader: AssetFixtureLoader(
        loadString: (_) async => _fallbackNewsJson,
      ),
    );

    await tester.pumpWidget(
      _TestApp(home: NewsPage(repository: repository), wrapInScaffold: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fallback story'), findsOneWidget);
    expect(find.textContaining('Showing bundled demo headlines'), findsNothing);
    expect(find.text('News feed unavailable'), findsNothing);
  });

  testWidgets('ScorePage shows demo games when fallback data is used', (
    WidgetTester tester,
  ) async {
    final BasketballRepository repository = BasketballRepository(
      service: NbaApiService(apiKey: ''),
      fixtureLoader: AssetFixtureLoader(
        loadString: (_) async => _fallbackGamesJson,
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        home: ScorePage(
          repository: repository,
          contentRepository: _fakeScoreboardContentRepository(),
        ),
        wrapInScaffold: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Golden State Warriors'), findsOneWidget);
    expect(find.text('Scoreboard unavailable'), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.home, this.wrapInScaffold = false});

  final Widget home;
  final bool wrapInScaffold;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: wrapInScaffold ? Scaffold(body: home) : home,
    );
  }
}

class _FakeNewsRepository implements NewsFeedRepository {
  _FakeNewsRepository(this.loader);

  final Future<List<Article>> Function() loader;

  @override
  Future<List<Article>> fetchLatestNbaNews() => loader();
}

class _WidgetFakeProvider implements NewsProvider {
  _WidgetFakeProvider({required this.name, required this.loader});

  final String name;
  final Future<List<Article>> Function() loader;

  @override
  String get providerName => name;

  @override
  Future<List<Article>> fetchLatestNbaNews() => loader();
}

class _FakeBasketballRepository implements BasketballDataRepository {
  _FakeBasketballRepository({
    required this.upcomingGames,
    required this.previousGames,
    required this.dashboard,
  });

  final List<Game> upcomingGames;
  final List<Game> previousGames;
  final StatsDashboard dashboard;
  final List<int> requestedStatsSeasons = <int>[];

  @override
  Future<List<Game>> fetchGamesForDate(DateTime date) async => previousGames;

  @override
  Future<List<Game>> fetchRecentGames({int days = 4}) async => previousGames;

  @override
  Future<List<Game>> fetchUpcomingGames({int days = 7}) async => upcomingGames;

  @override
  Future<List<Game>> fetchPreviousGames({int days = 14}) async => previousGames;

  @override
  Future<StatsDashboard> fetchStatsDashboard({required int season}) async {
    requestedStatsSeasons.add(season);
    return dashboard;
  }
}

class _ChromeTestPage extends StatelessWidget {
  const _ChromeTestPage({required this.onChromeVisibilityChanged});

  final ChromeVisibilityChanged onChromeVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return _ChromeTestScrollView(
      onChromeVisibilityChanged: onChromeVisibilityChanged,
    );
  }
}

class _ChromeTestScrollView extends StatefulWidget {
  const _ChromeTestScrollView({required this.onChromeVisibilityChanged});

  final ChromeVisibilityChanged onChromeVisibilityChanged;

  @override
  State<_ChromeTestScrollView> createState() => _ChromeTestScrollViewState();
}

class _ChromeTestScrollViewState extends State<_ChromeTestScrollView> {
  late final ScrollController _controller;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final double offset = _controller.offset;
    if (offset <= 24) {
      widget.onChromeVisibilityChanged(true);
    } else if (offset > _lastOffset) {
      widget.onChromeVisibilityChanged(false);
    } else if (offset < _lastOffset) {
      widget.onChromeVisibilityChanged(true);
    }
    _lastOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('chrome-test-list'),
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 40,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(title: Text('Story $index'));
      },
    );
  }
}

List<Article> _sampleArticles() {
  return <Article>[
    Article(
      title: 'Top headline',
      description: 'Lead story summary',
      url: 'https://example.com/featured',
      publishedAt: DateTime.parse('2026-03-17T12:00:00Z'),
      source: 'ESPN',
      urlToImage: null,
      author: 'Reporter One',
      content: 'Lead story content',
    ),
    Article(
      title: 'Bench unit update',
      description: 'Secondary summary',
      url: 'https://example.com/secondary',
      publishedAt: DateTime.parse('2026-03-17T10:00:00Z'),
      source: 'The Athletic',
      urlToImage: null,
    ),
    Article(
      title: 'Trade market watch',
      description: 'Third story summary',
      url: 'https://example.com/trade',
      publishedAt: DateTime.parse('2026-03-17T09:00:00Z'),
      source: 'Yahoo Sports',
      urlToImage: null,
    ),
  ];
}

Game _game({
  required int id,
  required Team home,
  required Team visitor,
  String status = 'Final',
  String date = '2026-03-17T12:00:00Z',
  int homeTeamScore = 120,
  int visitorTeamScore = 115,
}) {
  return Game(
    id: id,
    date: date,
    homeTeamScore: homeTeamScore,
    visitorTeamScore: visitorTeamScore,
    season: 2025,
    period: 4,
    status: status,
    time: '',
    postseason: false,
    postponed: false,
    homeTeam: home,
    visitorTeam: visitor,
  );
}

Team _team(int id, String abbreviation, String fullName, String conference) {
  return Team(
    id: id,
    abbreviation: abbreviation,
    city: fullName.split(' ').first,
    conference: conference,
    division: 'Atlantic',
    fullName: fullName,
    name: fullName.split(' ').last,
  );
}

StatsDashboard _dashboard() {
  final Team warriors = _team(10, 'GSW', 'Golden State Warriors', 'West');
  final Team celtics = _team(2, 'BOS', 'Boston Celtics', 'East');
  final Team lakers = _team(14, 'LAL', 'Los Angeles Lakers', 'West');
  final Team knicks = _team(5, 'NYK', 'New York Knicks', 'East');
  final Team thunder = _team(25, 'OKC', 'Oklahoma City Thunder', 'West');
  final Team heat = _team(22, 'MIA', 'Miami Heat', 'East');

  return StatsDashboard(
    season: 2025,
    teamsById: <int, Team>{
      warriors.id: warriors,
      celtics.id: celtics,
      lakers.id: lakers,
      knicks.id: knicks,
      thunder.id: thunder,
      heat.id: heat,
    },
    standings: <TeamStanding>[
      TeamStanding(
        team: celtics,
        conferenceRecord: '40-10',
        conferenceRank: 1,
        divisionRecord: '10-2',
        divisionRank: 1,
        wins: 52,
        losses: 20,
        homeRecord: '28-8',
        roadRecord: '24-12',
        season: 2025,
      ),
      TeamStanding(
        team: knicks,
        conferenceRecord: '35-15',
        conferenceRank: 2,
        divisionRecord: '9-4',
        divisionRank: 2,
        wins: 49,
        losses: 23,
        homeRecord: '26-10',
        roadRecord: '23-13',
        season: 2025,
      ),
      TeamStanding(
        team: heat,
        conferenceRecord: '31-19',
        conferenceRank: 3,
        divisionRecord: '8-5',
        divisionRank: 2,
        wins: 45,
        losses: 27,
        homeRecord: '24-12',
        roadRecord: '21-15',
        season: 2025,
      ),
      TeamStanding(
        team: thunder,
        conferenceRecord: '39-11',
        conferenceRank: 1,
        divisionRecord: '12-2',
        divisionRank: 1,
        wins: 53,
        losses: 19,
        homeRecord: '28-8',
        roadRecord: '25-11',
        season: 2025,
      ),
      TeamStanding(
        team: warriors,
        conferenceRecord: '38-12',
        conferenceRank: 2,
        divisionRecord: '11-3',
        divisionRank: 1,
        wins: 50,
        losses: 22,
        homeRecord: '27-9',
        roadRecord: '23-13',
        season: 2025,
      ),
      TeamStanding(
        team: lakers,
        conferenceRecord: '34-16',
        conferenceRank: 3,
        divisionRecord: '10-4',
        divisionRank: 2,
        wins: 48,
        losses: 24,
        homeRecord: '25-11',
        roadRecord: '23-13',
        season: 2025,
      ),
    ],
    teamStatsById: <int, TeamSeasonStats>{
      celtics.id: TeamSeasonStats(
        team: celtics,
        season: 2025,
        seasonType: 'regular',
        wins: 52,
        losses: 20,
        gamesPlayed: 72,
        points: 118.2,
        rebounds: 45.0,
        assists: 28.5,
        steals: 8.1,
        blocks: 5.4,
        fieldGoalPct: 48.5,
        threePointPct: 38.1,
        plusMinus: 7.2,
      ),
      knicks.id: TeamSeasonStats(
        team: knicks,
        season: 2025,
        seasonType: 'regular',
        wins: 49,
        losses: 23,
        gamesPlayed: 72,
        points: 116.8,
        rebounds: 44.1,
        assists: 27.7,
        steals: 7.6,
        blocks: 4.4,
        fieldGoalPct: 47.4,
        threePointPct: 37.8,
        plusMinus: 5.0,
      ),
      heat.id: TeamSeasonStats(
        team: heat,
        season: 2025,
        seasonType: 'regular',
        wins: 45,
        losses: 27,
        gamesPlayed: 72,
        points: 112.9,
        rebounds: 42.8,
        assists: 25.1,
        steals: 8.2,
        blocks: 4.8,
        fieldGoalPct: 46.8,
        threePointPct: 36.6,
        plusMinus: 2.9,
      ),
      thunder.id: TeamSeasonStats(
        team: thunder,
        season: 2025,
        seasonType: 'regular',
        wins: 53,
        losses: 19,
        gamesPlayed: 72,
        points: 119.3,
        rebounds: 45.2,
        assists: 29.4,
        steals: 8.9,
        blocks: 6.2,
        fieldGoalPct: 49.2,
        threePointPct: 38.4,
        plusMinus: 8.1,
      ),
      warriors.id: TeamSeasonStats(
        team: warriors,
        season: 2025,
        seasonType: 'regular',
        wins: 50,
        losses: 22,
        gamesPlayed: 72,
        points: 116.1,
        rebounds: 44.3,
        assists: 29.1,
        steals: 7.8,
        blocks: 4.9,
        fieldGoalPct: 47.2,
        threePointPct: 39.0,
        plusMinus: 5.7,
      ),
      lakers.id: TeamSeasonStats(
        team: lakers,
        season: 2025,
        seasonType: 'regular',
        wins: 48,
        losses: 24,
        gamesPlayed: 72,
        points: 117.4,
        rebounds: 43.5,
        assists: 28.3,
        steals: 7.5,
        blocks: 5.7,
        fieldGoalPct: 48.1,
        threePointPct: 37.1,
        plusMinus: 4.6,
      ),
    },
    leadersByStat: <String, List<PlayerLeader>>{
      'pts': <PlayerLeader>[
        PlayerLeader(
          player: const Player(
            id: 30,
            firstName: 'Stephen',
            lastName: 'Curry',
            position: 'G',
            teamId: 10,
          ),
          value: 31.2,
          statType: 'pts',
          rank: 1,
          season: 2025,
          gamesPlayed: 68,
        ),
        PlayerLeader(
          player: const Player(
            id: 31,
            firstName: 'Shai',
            lastName: 'Gilgeous-Alexander',
            position: 'G',
            teamId: 25,
          ),
          value: 30.4,
          statType: 'pts',
          rank: 2,
          season: 2025,
          gamesPlayed: 69,
        ),
        PlayerLeader(
          player: const Player(
            id: 32,
            firstName: 'Jayson',
            lastName: 'Tatum',
            position: 'F',
            teamId: 2,
          ),
          value: 29.6,
          statType: 'pts',
          rank: 3,
          season: 2025,
          gamesPlayed: 70,
        ),
        PlayerLeader(
          player: const Player(
            id: 33,
            firstName: 'Jalen',
            lastName: 'Brunson',
            position: 'G',
            teamId: 5,
          ),
          value: 28.1,
          statType: 'pts',
          rank: 4,
          season: 2025,
          gamesPlayed: 67,
        ),
        PlayerLeader(
          player: const Player(
            id: 34,
            firstName: 'LeBron',
            lastName: 'James',
            position: 'F',
            teamId: 14,
          ),
          value: 27.5,
          statType: 'pts',
          rank: 5,
          season: 2025,
          gamesPlayed: 64,
        ),
      ],
      'reb': <PlayerLeader>[
        PlayerLeader(
          player: const Player(
            id: 35,
            firstName: 'Anthony',
            lastName: 'Davis',
            position: 'C',
            teamId: 14,
          ),
          value: 12.3,
          statType: 'reb',
          rank: 1,
          season: 2025,
          gamesPlayed: 61,
        ),
        PlayerLeader(
          player: const Player(
            id: 36,
            firstName: 'Bam',
            lastName: 'Adebayo',
            position: 'C',
            teamId: 22,
          ),
          value: 11.2,
          statType: 'reb',
          rank: 2,
          season: 2025,
          gamesPlayed: 69,
        ),
        PlayerLeader(
          player: const Player(
            id: 37,
            firstName: 'Isaiah',
            lastName: 'Hartenstein',
            position: 'C',
            teamId: 25,
          ),
          value: 10.8,
          statType: 'reb',
          rank: 3,
          season: 2025,
          gamesPlayed: 66,
        ),
      ],
      'ast': <PlayerLeader>[
        PlayerLeader(
          player: const Player(
            id: 34,
            firstName: 'LeBron',
            lastName: 'James',
            position: 'F',
            teamId: 14,
          ),
          value: 9.8,
          statType: 'ast',
          rank: 1,
          season: 2025,
          gamesPlayed: 64,
        ),
        PlayerLeader(
          player: const Player(
            id: 30,
            firstName: 'Stephen',
            lastName: 'Curry',
            position: 'G',
            teamId: 10,
          ),
          value: 8.7,
          statType: 'ast',
          rank: 2,
          season: 2025,
          gamesPlayed: 68,
        ),
        PlayerLeader(
          player: const Player(
            id: 33,
            firstName: 'Jalen',
            lastName: 'Brunson',
            position: 'G',
            teamId: 5,
          ),
          value: 8.4,
          statType: 'ast',
          rank: 3,
          season: 2025,
          gamesPlayed: 67,
        ),
      ],
      'stl': <PlayerLeader>[
        PlayerLeader(
          player: const Player(
            id: 31,
            firstName: 'Shai',
            lastName: 'Gilgeous-Alexander',
            position: 'G',
            teamId: 25,
          ),
          value: 2.3,
          statType: 'stl',
          rank: 1,
          season: 2025,
          gamesPlayed: 69,
        ),
        PlayerLeader(
          player: const Player(
            id: 38,
            firstName: 'Jimmy',
            lastName: 'Butler',
            position: 'F',
            teamId: 22,
          ),
          value: 2.0,
          statType: 'stl',
          rank: 2,
          season: 2025,
          gamesPlayed: 58,
        ),
        PlayerLeader(
          player: const Player(
            id: 30,
            firstName: 'Stephen',
            lastName: 'Curry',
            position: 'G',
            teamId: 10,
          ),
          value: 1.9,
          statType: 'stl',
          rank: 3,
          season: 2025,
          gamesPlayed: 68,
        ),
      ],
      'blk': <PlayerLeader>[
        PlayerLeader(
          player: const Player(
            id: 35,
            firstName: 'Anthony',
            lastName: 'Davis',
            position: 'C',
            teamId: 14,
          ),
          value: 2.5,
          statType: 'blk',
          rank: 1,
          season: 2025,
          gamesPlayed: 61,
        ),
        PlayerLeader(
          player: const Player(
            id: 39,
            firstName: 'Chet',
            lastName: 'Holmgren',
            position: 'C',
            teamId: 25,
          ),
          value: 2.2,
          statType: 'blk',
          rank: 2,
          season: 2025,
          gamesPlayed: 63,
        ),
        PlayerLeader(
          player: const Player(
            id: 36,
            firstName: 'Bam',
            lastName: 'Adebayo',
            position: 'C',
            teamId: 22,
          ),
          value: 1.8,
          statType: 'blk',
          rank: 3,
          season: 2025,
          gamesPlayed: 69,
        ),
      ],
    },
    warnings: const <String>[],
  );
}

int _currentNbaSeasonForTest() {
  final DateTime now = DateTime.now();
  return now.month >= 10 ? now.year : now.year - 1;
}

String _seasonLabelForTest(int season) {
  return '$season-${(season + 1).toString().substring(2)}';
}

const String _fallbackNewsJson = '''
[
  {
    "title": "Fallback story",
    "description": "Fallback summary",
    "url": "https://example.com/fallback-story",
    "publishedAt": "2026-03-18T10:00:00Z",
    "source": {
      "name": "Fallback Wire"
    },
    "urlToImage": null,
    "fallback_offset_hours": 2
  },
  {
    "title": "Second fallback",
    "description": "Another summary",
    "url": "https://example.com/second-fallback",
    "publishedAt": "2026-03-18T08:00:00Z",
    "source": {
      "name": "Fallback Wire"
    },
    "urlToImage": null,
    "fallback_offset_hours": 4
  }
]
''';

const String _fallbackGamesJson = '''
[
  {
    "id": 101,
    "date": "2026-03-18T00:30:00Z",
    "home_team_score": 118,
    "visitor_team_score": 112,
    "season": 2025,
    "period": 4,
    "status": "Final",
    "time": "7:30 PM ET",
    "postseason": false,
    "postponed": false,
    "fallback_relative_day_offset": 0,
    "home_team": {
      "id": 14,
      "abbreviation": "LAL",
      "city": "Los Angeles",
      "conference": "West",
      "division": "Pacific",
      "full_name": "Los Angeles Lakers",
      "name": "Lakers"
    },
    "visitor_team": {
      "id": 2,
      "abbreviation": "BOS",
      "city": "Boston",
      "conference": "East",
      "division": "Atlantic",
      "full_name": "Boston Celtics",
      "name": "Celtics"
    }
  },
  {
    "id": 102,
    "date": "2026-03-18T02:00:00Z",
    "home_team_score": 99,
    "visitor_team_score": 104,
    "season": 2025,
    "period": 3,
    "status": "3rd Qtr",
    "time": "9:00 PM ET",
    "postseason": false,
    "postponed": false,
    "fallback_relative_day_offset": 0,
    "home_team": {
      "id": 10,
      "abbreviation": "GSW",
      "city": "Golden State",
      "conference": "West",
      "division": "Pacific",
      "full_name": "Golden State Warriors",
      "name": "Warriors"
    },
    "visitor_team": {
      "id": 25,
      "abbreviation": "OKC",
      "city": "Oklahoma City",
      "conference": "West",
      "division": "Northwest",
      "full_name": "Oklahoma City Thunder",
      "name": "Thunder"
    }
  }
]
''';

ScoreboardContentRepository _fakeScoreboardContentRepository() {
  return _scoreboardContentRepositoryWithBranding(_teamBrandingJson);
}

ScoreboardContentRepository _emptyBrandingContentRepository() {
  return _scoreboardContentRepositoryWithBranding('{}');
}

ScoreboardContentRepository _scoreboardContentRepositoryWithBranding(
  String brandingJson,
) {
  return ScoreboardContentRepository(
    fixtureLoader: AssetFixtureLoader(
      loadString: (String path) async {
        switch (path) {
          case 'assets/data/team_branding.json':
            return brandingJson;
          case 'assets/data/game_details.json':
            return _gameDetailsJson;
          default:
            throw ArgumentError('Unexpected asset path: $path');
        }
      },
    ),
  );
}

const String _teamBrandingJson = '''
{
  "BOS": {"logoAsset": "images/nba/BOS.png", "primaryColor": "#007A33"},
  "GSW": {"logoAsset": "images/nba/GSW.png", "primaryColor": "#1D428A"},
  "LAL": {"logoAsset": "images/nba/LAL.png", "primaryColor": "#552583"},
  "MIA": {"logoAsset": "images/nba/MIA.png", "primaryColor": "#98002E"},
  "NYK": {"logoAsset": "images/nba/NYK.png", "primaryColor": "#006BB6"},
  "OKC": {"logoAsset": "images/nba/OKC.png", "primaryColor": "#007AC1"}
}
''';

const String _gameDetailsJson = '''
{
  "11": {
    "arena": "Chase Center",
    "location": "San Francisco, California",
    "headline": "Thunder pressure Golden State in a live matchup",
    "summary": "Oklahoma City has pushed the pace and kept Golden State scrambling in transition, while the Warriors are still in range thanks to half-court shotmaking.",
    "notes": [
      "Thunder lead the transition scoring battle.",
      "Warriors are living from deep late in the third."
    ],
    "homeLineScores": [31, 33, 39],
    "visitorLineScores": [35, 36, 38]
  }
}
''';
