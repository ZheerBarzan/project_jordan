import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/UI/article_reader_page.dart';
import 'package:project_jordan/UI/home_page.dart';
import 'package:project_jordan/UI/news_page.dart';
import 'package:project_jordan/UI/score_page.dart';
import 'package:project_jordan/UI/stats_page.dart';
import 'package:project_jordan/components/scroll_chrome.dart';
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
    'NewsPage switches layouts, removes card buttons, and opens reader',
    (WidgetTester tester) async {
      final _FakeNewsRepository repository = _FakeNewsRepository(
        () async => _sampleArticles(),
      );

      await tester.pumpWidget(
        _TestApp(
          home: NewsPage(
            repository: repository,
            readerPageBuilder: (BuildContext context, Article article) {
              return Scaffold(
                body: Center(child: Text('Reader: ${article.title}')),
              );
            },
          ),
          wrapInScaffold: true,
        ),
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

      expect(find.text('Reader: Top headline'), findsOneWidget);
    },
  );

  testWidgets('ArticleReaderPage shows retry and browser fallback on error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        home: ArticleReaderPage(
          article: _sampleArticles().first,
          initialReaderError: Exception('Embedded reader failed'),
        ),
      ),
    );

    expect(
      find.byKey(const Key('article-reader-inline-message')),
      findsOneWidget,
    );
    expect(find.text('Could not load the article'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Open in Browser'), findsOneWidget);
  });

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

  testWidgets('ScorePage switches between today and recent windows', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      todayGames: <Game>[
        _game(
          id: 1,
          home: _team(14, 'LAL', 'Los Angeles Lakers', 'West'),
          visitor: _team(2, 'BOS', 'Boston Celtics', 'East'),
        ),
      ],
      recentGames: <Game>[
        _game(
          id: 2,
          home: _team(5, 'NYK', 'New York Knicks', 'East'),
          visitor: _team(22, 'MIA', 'Miami Heat', 'East'),
          status: '7:30 PM ET',
        ),
      ],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(home: ScorePage(repository: repository), wrapInScaffold: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Los Angeles Lakers'), findsOneWidget);

    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    expect(find.text('New York Knicks'), findsOneWidget);
    expect(find.text('Los Angeles Lakers'), findsNothing);
  });

  testWidgets('StatsPage switches from teams to players section', (
    WidgetTester tester,
  ) async {
    final _FakeBasketballRepository repository = _FakeBasketballRepository(
      todayGames: <Game>[],
      recentGames: <Game>[],
      dashboard: _dashboard(),
    );

    await tester.pumpWidget(
      _TestApp(home: StatsPage(repository: repository), wrapInScaffold: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eastern Conference'), findsOneWidget);

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    expect(find.text('Points Leaders'), findsOneWidget);
    expect(find.text('Stephen Curry'), findsOneWidget);
  });

  testWidgets('NewsPage shows fallback banner and demo content', (
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

    expect(
      find.textContaining('Showing bundled demo headlines'),
      findsOneWidget,
    );
    expect(find.text('Fallback story'), findsOneWidget);
    expect(find.text('News feed unavailable'), findsNothing);
  });

  testWidgets('ScorePage shows fallback banner and demo games', (
    WidgetTester tester,
  ) async {
    final BasketballRepository repository = BasketballRepository(
      service: NbaApiService(apiKey: ''),
      fixtureLoader: AssetFixtureLoader(
        loadString: (_) async => _fallbackGamesJson,
      ),
    );

    await tester.pumpWidget(
      _TestApp(home: ScorePage(repository: repository), wrapInScaffold: true),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Showing bundled demo scoreboard data'),
      findsOneWidget,
    );
    expect(find.text('Los Angeles Lakers'), findsOneWidget);
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
    required this.todayGames,
    required this.recentGames,
    required this.dashboard,
  });

  final List<Game> todayGames;
  final List<Game> recentGames;
  final StatsDashboard dashboard;

  @override
  Future<List<Game>> fetchGamesForDate(DateTime date) async => todayGames;

  @override
  Future<List<Game>> fetchRecentGames({int days = 4}) async => recentGames;

  @override
  Future<StatsDashboard> fetchStatsDashboard({required int season}) async =>
      dashboard;
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
}) {
  return Game(
    id: id,
    date: '2026-03-17T12:00:00Z',
    homeTeamScore: 120,
    visitorTeamScore: 115,
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

  return StatsDashboard(
    season: 2025,
    teamsById: <int, Team>{warriors.id: warriors, celtics.id: celtics},
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
        team: warriors,
        conferenceRecord: '38-12',
        conferenceRank: 1,
        divisionRecord: '11-3',
        divisionRank: 1,
        wins: 50,
        losses: 22,
        homeRecord: '27-9',
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
      ],
    },
    warnings: const <String>[],
  );
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
    "fallback_day_offset": 0,
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
    "fallback_day_offset": 0,
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
