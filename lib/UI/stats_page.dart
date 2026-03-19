import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:project_jordan/components/scroll_chrome.dart';
import 'package:project_jordan/components/team_logo_badge.dart';
import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/stats_dashboard.dart';
import 'package:project_jordan/model/team_branding.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/repositories/basketball_repository.dart';
import 'package:project_jordan/repositories/scoreboard_content_repository.dart';
import 'package:project_jordan/theme/app_theme.dart';

const List<String> _leaderStatOrder = <String>[
  'pts',
  'reb',
  'ast',
  'stl',
  'blk',
];

enum _StatsSection { standings, leaders }

enum _ConferenceFocus { east, west }

class StatsPage extends StatefulWidget {
  StatsPage({
    super.key,
    BasketballDataRepository? repository,
    ScoreboardContentRepository? contentRepository,
    this.onChromeVisibilityChanged,
  }) : repository = repository ?? BasketballRepository(),
       contentRepository = contentRepository ?? ScoreboardContentRepository();

  final BasketballDataRepository repository;
  final ScoreboardContentRepository contentRepository;
  final ChromeVisibilityChanged? onChromeVisibilityChanged;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<_StatsViewData> _futureData;
  late final int _currentSeason = _currentNbaSeason(DateTime.now());
  late final List<int> _seasonOptions = List<int>.generate(
    5,
    (int index) => _currentSeason - index,
  );
  late int _selectedSeason = _currentSeason;
  _StatsSection _section = _StatsSection.standings;
  _ConferenceFocus _conferenceFocus = _ConferenceFocus.east;
  String _selectedLeaderStat = _leaderStatOrder.first;

  @override
  void initState() {
    super.initState();
    _futureData = _loadData();
  }

  Future<_StatsViewData> _loadData() async {
    final Future<StatsDashboard> dashboardFuture = widget.repository
        .fetchStatsDashboard(season: _selectedSeason);
    final Future<Map<String, TeamBranding>> brandingFuture =
        _loadBrandingSafe();

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      dashboardFuture,
      brandingFuture,
    ]);

    return _StatsViewData(
      dashboard: results[0] as StatsDashboard,
      brandingByAbbreviation: results[1] as Map<String, TeamBranding>,
    );
  }

  Future<Map<String, TeamBranding>> _loadBrandingSafe() async {
    try {
      return await widget.contentRepository.loadTeamBranding();
    } catch (_) {
      return <String, TeamBranding>{};
    }
  }

  Future<void> _reload() async {
    setState(() {
      _futureData = _loadData();
    });
    await _futureData;
  }

  void _changeSeason(int? season) {
    if (season == null || season == _selectedSeason) {
      return;
    }

    setState(() {
      _selectedSeason = season;
      _futureData = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StatsViewData>(
      future: _futureData,
      builder: (BuildContext context, AsyncSnapshot<_StatsViewData> snapshot) {
        return NotificationListener<UserScrollNotification>(
          onNotification: _handleScrollNotification,
          child: RefreshIndicator(
            color: AppTheme.accentRed,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _StatsHero(season: _selectedSeason, section: _section),
                        const SizedBox(height: 18),
                        _StatsToolbar(
                          currentSection: _section,
                          seasonOptions: _seasonOptions,
                          selectedSeason: _selectedSeason,
                          onSectionChanged: (_StatsSection section) {
                            setState(() {
                              _section = section;
                            });
                          },
                          onSeasonChanged: _changeSeason,
                        ),
                        const SizedBox(height: 18),
                        _buildBody(context, snapshot),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _handleScrollNotification(UserScrollNotification notification) {
    final ChromeVisibilityChanged? callback = widget.onChromeVisibilityChanged;
    if (callback == null || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification.metrics.pixels <= 24) {
      callback(true);
    } else if (notification.direction == ScrollDirection.reverse) {
      callback(false);
    } else if (notification.direction == ScrollDirection.forward) {
      callback(true);
    }

    return false;
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<_StatsViewData> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _StatsStateCard(
        icon: Icons.insights_rounded,
        title: 'Loading stats dashboard',
        message: 'Fetching standings, team averages, and leaderboards.',
        showProgress: true,
      );
    }

    if (snapshot.hasError) {
      return _StatsStateCard(
        icon: Icons.error_outline,
        title: 'Stats unavailable',
        message: snapshot.error.toString(),
        actionLabel: 'Retry',
        onAction: _reload,
      );
    }

    final _StatsViewData data = snapshot.data!;
    final StatsDashboard dashboard = data.dashboard;
    final List<String> availableLeaderStats = _availableLeaderStats(dashboard);
    final String activeStat = availableLeaderStats.contains(_selectedLeaderStat)
        ? _selectedLeaderStat
        : (availableLeaderStats.isNotEmpty
              ? availableLeaderStats.first
              : _leaderStatOrder.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (dashboard.warnings.isNotEmpty) ...<Widget>[
          _WarningBanner(messages: dashboard.warnings),
          const SizedBox(height: 16),
        ],
        if (_section == _StatsSection.standings)
          _StandingsDashboard(
            dashboard: dashboard,
            brandingByAbbreviation: data.brandingByAbbreviation,
            conferenceFocus: _conferenceFocus,
            onConferenceFocusChanged: (_ConferenceFocus focus) {
              setState(() {
                _conferenceFocus = focus;
              });
            },
          )
        else
          _LeadersDashboard(
            dashboard: dashboard,
            brandingByAbbreviation: data.brandingByAbbreviation,
            selectedStat: activeStat,
            onStatChanged: (String statType) {
              setState(() {
                _selectedLeaderStat = statType;
              });
            },
          ),
      ],
    );
  }

  List<String> _availableLeaderStats(StatsDashboard dashboard) {
    return _leaderStatOrder
        .where(
          (String statType) =>
              (dashboard.leadersByStat[statType] ?? const <PlayerLeader>[])
                  .isNotEmpty,
        )
        .toList();
  }

  int _currentNbaSeason(DateTime now) {
    return now.month >= 10 ? now.year : now.year - 1;
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({required this.season, required this.section});

  final int season;
  final _StatsSection section;

  @override
  Widget build(BuildContext context) {
    final String sectionLabel = section == _StatsSection.standings
        ? 'Conference Race'
        : 'League Leaders';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF9FBFF), Color(0xFFEAF1FF)],
        ),
        border: Border.all(color: AppTheme.paperLine),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x110A2342),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -48,
              top: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.nbaBlue.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              left: -26,
              bottom: -54,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentRed.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              right: 34,
              bottom: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppTheme.courtBlue, AppTheme.nbaBlue],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Icon(
                    Icons.sports_basketball_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.nbaBlue.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      'NBA • ${_seasonLabel(season)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.courtBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stats Central',
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(color: AppTheme.ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A sharper look at the playoff race, team form, and the players driving the season.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.ink.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _HeroMetricChip(
                        label: 'Focus',
                        value: sectionLabel,
                        accent: AppTheme.accentRed,
                      ),
                      _HeroMetricChip(
                        label: 'Format',
                        value: 'Standings + Leaders',
                        accent: AppTheme.nbaBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsToolbar extends StatelessWidget {
  const _StatsToolbar({
    required this.currentSection,
    required this.seasonOptions,
    required this.selectedSeason,
    required this.onSectionChanged,
    required this.onSeasonChanged,
  });

  final _StatsSection currentSection;
  final List<int> seasonOptions;
  final int selectedSeason;
  final ValueChanged<_StatsSection> onSectionChanged;
  final ValueChanged<int?> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.paperLine),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SegmentedButton<_StatsSection>(
            key: const Key('stats-primary-tabs'),
            segments: const <ButtonSegment<_StatsSection>>[
              ButtonSegment<_StatsSection>(
                value: _StatsSection.standings,
                label: Text('Standings'),
                icon: Icon(Icons.table_chart_rounded),
              ),
              ButtonSegment<_StatsSection>(
                value: _StatsSection.leaders,
                label: Text('Leaders'),
                icon: Icon(Icons.equalizer_rounded),
              ),
            ],
            selected: <_StatsSection>{currentSection},
            onSelectionChanged: (Set<_StatsSection> selection) {
              onSectionChanged(selection.first);
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.softBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.paperLine),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: const Key('stats-season-selector'),
                value: selectedSeason,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                borderRadius: BorderRadius.circular(18),
                dropdownColor: Colors.white,
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: onSeasonChanged,
                items: seasonOptions.map((int season) {
                  return DropdownMenuItem<int>(
                    value: season,
                    child: Text(_seasonLabel(season)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7C46C)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A5A00)),
              const SizedBox(width: 10),
              Text(
                'Partial Data',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...messages.map((String message) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '• $message',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StandingsDashboard extends StatelessWidget {
  const _StandingsDashboard({
    required this.dashboard,
    required this.brandingByAbbreviation,
    required this.conferenceFocus,
    required this.onConferenceFocusChanged,
  });

  final StatsDashboard dashboard;
  final Map<String, TeamBranding> brandingByAbbreviation;
  final _ConferenceFocus conferenceFocus;
  final ValueChanged<_ConferenceFocus> onConferenceFocusChanged;

  @override
  Widget build(BuildContext context) {
    if (dashboard.standings.isEmpty) {
      return const _StatsStateCard(
        icon: Icons.table_chart_outlined,
        title: 'No team standings available',
        message:
            'Standings and team averages need a BallDontLie tier that exposes those endpoints.',
      );
    }

    final List<TeamStanding> east = dashboard.standingsForConference('East');
    final List<TeamStanding> west = dashboard.standingsForConference('West');

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showTwoColumns = constraints.maxWidth >= 920;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: <Widget>[
                SizedBox(
                  width: showTwoColumns
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: _ConferenceOverviewCard(
                    title: 'Eastern Conference',
                    standings: east,
                    brandingByAbbreviation: brandingByAbbreviation,
                  ),
                ),
                SizedBox(
                  width: showTwoColumns
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: _ConferenceOverviewCard(
                    title: 'Western Conference',
                    standings: west,
                    brandingByAbbreviation: brandingByAbbreviation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (showTwoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _ConferenceTableCard(
                      key: const Key('stats-table-east'),
                      title: 'Eastern Conference',
                      standings: east,
                      dashboard: dashboard,
                      brandingByAbbreviation: brandingByAbbreviation,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ConferenceTableCard(
                      key: const Key('stats-table-west'),
                      title: 'Western Conference',
                      standings: west,
                      dashboard: dashboard,
                      brandingByAbbreviation: brandingByAbbreviation,
                    ),
                  ),
                ],
              )
            else ...<Widget>[
              Container(
                key: const Key('stats-conference-switcher'),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.paperLine),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ChoiceChip(
                      label: const Text('East'),
                      selected: conferenceFocus == _ConferenceFocus.east,
                      onSelected: (_) {
                        onConferenceFocusChanged(_ConferenceFocus.east);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('West'),
                      selected: conferenceFocus == _ConferenceFocus.west,
                      onSelected: (_) {
                        onConferenceFocusChanged(_ConferenceFocus.west);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConferenceTableCard(
                key: conferenceFocus == _ConferenceFocus.east
                    ? const Key('stats-table-east')
                    : const Key('stats-table-west'),
                title: conferenceFocus == _ConferenceFocus.east
                    ? 'Eastern Conference'
                    : 'Western Conference',
                standings: conferenceFocus == _ConferenceFocus.east
                    ? east
                    : west,
                dashboard: dashboard,
                brandingByAbbreviation: brandingByAbbreviation,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ConferenceOverviewCard extends StatelessWidget {
  const _ConferenceOverviewCard({
    required this.title,
    required this.standings,
    required this.brandingByAbbreviation,
  });

  final String title;
  final List<TeamStanding> standings;
  final Map<String, TeamBranding> brandingByAbbreviation;

  @override
  Widget build(BuildContext context) {
    final TeamStanding? leader = standings.isNotEmpty ? standings.first : null;
    final TeamBranding? branding = leader == null
        ? null
        : brandingByAbbreviation[leader.team.abbreviation.toUpperCase()];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (leader == null)
              Text(
                'Standings are not available for this conference.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Row(
                children: <Widget>[
                  TeamLogoBadge(
                    abbreviation: leader.team.abbreviation,
                    teamName: leader.team.fullName,
                    branding: branding,
                    size: 46,
                    borderRadius: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Top seed',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          leader.team.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${leader.wins}-${leader.losses}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: branding?.primaryColorValue != null
                          ? Color(branding!.primaryColorValue!)
                          : AppTheme.accentRed,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ConferenceTableCard extends StatelessWidget {
  const _ConferenceTableCard({
    super.key,
    required this.title,
    required this.standings,
    required this.dashboard,
    required this.brandingByAbbreviation,
  });

  final String title;
  final List<TeamStanding> standings;
  final StatsDashboard dashboard;
  final Map<String, TeamBranding> brandingByAbbreviation;

  @override
  Widget build(BuildContext context) {
    final TeamStanding? topSeed = standings.isNotEmpty ? standings.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              topSeed == null
                  ? 'No standings data available.'
                  : 'Top seed: ${topSeed.team.fullName} • ${topSeed.wins}-${topSeed.losses}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 560;

                return Column(
                  children: <Widget>[
                    _ConferenceTableHeader(compact: compact),
                    const SizedBox(height: 8),
                    ...standings.asMap().entries.map((
                      MapEntry<int, TeamStanding> entry,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == standings.length - 1 ? 0 : 10,
                        ),
                        child: _StandingRow(
                          key: Key(
                            'stats-standing-row-${entry.value.team.abbreviation.toUpperCase()}',
                          ),
                          standing: entry.value,
                          stats: dashboard.teamStatsById[entry.value.team.id],
                          branding:
                              brandingByAbbreviation[entry
                                  .value
                                  .team
                                  .abbreviation
                                  .toUpperCase()],
                          compact: compact,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConferenceTableHeader extends StatelessWidget {
  const _ConferenceTableHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.softBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text('#', style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: compact ? 6 : 5,
            child: Text('Team', style: Theme.of(context).textTheme.bodySmall),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'W-L',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              'Win%',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (!compact) ...<Widget>[
            _HeaderMetricCell(label: 'Home'),
            _HeaderMetricCell(label: 'Road'),
            _HeaderMetricCell(label: 'Conf'),
            _HeaderMetricCell(label: 'PPG'),
          ],
        ],
      ),
    );
  }
}

class _HeaderMetricCell extends StatelessWidget {
  const _HeaderMetricCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    super.key,
    required this.standing,
    required this.stats,
    required this.branding,
    required this.compact,
  });

  final TeamStanding standing;
  final TeamSeasonStats? stats;
  final TeamBranding? branding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color accent = branding?.primaryColorValue != null
        ? Color(branding!.primaryColorValue!)
        : AppTheme.nbaBlue;
    final bool isTopSix = standing.conferenceRank <= 6;
    final bool isPlayIn =
        standing.conferenceRank >= 7 && standing.conferenceRank <= 10;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: isTopSix
              ? 0.10
              : isPlayIn
              ? 0.05
              : 0.025,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: isTopSix ? 0.22 : 0.10),
        ),
      ),
      child: compact
          ? _buildCompactRow(context, accent)
          : _buildWideRow(context, accent),
    );
  }

  Widget _buildWideRow(BuildContext context, Color accent) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          child: Text(
            '${standing.conferenceRank}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: accent),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: <Widget>[
              TeamLogoBadge(
                abbreviation: standing.team.abbreviation,
                teamName: standing.team.fullName,
                branding: branding,
                size: 40,
                borderRadius: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      standing.team.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      standing.team.abbreviation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _MetricValue(width: 60, value: '${standing.wins}-${standing.losses}'),
        _MetricValue(width: 64, value: _winPctLabel(standing)),
        _MetricValue(width: 56, value: standing.homeRecord),
        _MetricValue(width: 56, value: standing.roadRecord),
        _MetricValue(width: 56, value: standing.conferenceRecord),
        _MetricValue(
          width: 56,
          value: stats != null ? stats!.points.toStringAsFixed(1) : '—',
          highlight: true,
          color: accent,
        ),
      ],
    );
  }

  Widget _buildCompactRow(BuildContext context, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(
              width: 28,
              child: Text(
                '${standing.conferenceRank}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: accent),
              ),
            ),
            TeamLogoBadge(
              abbreviation: standing.team.abbreviation,
              teamName: standing.team.fullName,
              branding: branding,
              size: 40,
              borderRadius: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    standing.team.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    standing.team.abbreviation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${standing.wins}-${standing.losses}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: accent),
                ),
                Text(
                  _winPctLabel(standing),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _CompactMetricChip(label: 'Home', value: standing.homeRecord),
            _CompactMetricChip(label: 'Road', value: standing.roadRecord),
            _CompactMetricChip(label: 'Conf', value: standing.conferenceRecord),
            _CompactMetricChip(
              label: 'PPG',
              value: stats != null ? stats!.points.toStringAsFixed(1) : '—',
              accent: accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({
    required this.width,
    required this.value,
    this.highlight = false,
    this.color,
  });

  final double width;
  final String value;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: highlight
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color ?? AppTheme.nbaBlue,
              )
            : Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _CompactMetricChip extends StatelessWidget {
  const _CompactMetricChip({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (accent ?? AppTheme.paperLine).withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _LeadersDashboard extends StatelessWidget {
  const _LeadersDashboard({
    required this.dashboard,
    required this.brandingByAbbreviation,
    required this.selectedStat,
    required this.onStatChanged,
  });

  final StatsDashboard dashboard;
  final Map<String, TeamBranding> brandingByAbbreviation;
  final String selectedStat;
  final ValueChanged<String> onStatChanged;

  @override
  Widget build(BuildContext context) {
    final List<String> availableStats = _leaderStatOrder
        .where(
          (String statType) =>
              (dashboard.leadersByStat[statType] ?? const <PlayerLeader>[])
                  .isNotEmpty,
        )
        .toList();

    if (availableStats.isEmpty) {
      return const _StatsStateCard(
        icon: Icons.person_search_outlined,
        title: 'No player leaderboards available',
        message:
            'Player leaderboards need BallDontLie access to the leaders endpoint.',
      );
    }

    final String activeStat = availableStats.contains(selectedStat)
        ? selectedStat
        : availableStats.first;
    final List<PlayerLeader> leaders =
        dashboard.leadersByStat[activeStat] ?? const <PlayerLeader>[];
    final List<PlayerLeader> featured = leaders.take(3).toList();
    final List<PlayerLeader> remaining = leaders.skip(3).toList();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumn = constraints.maxWidth >= 920;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              key: const Key('stats-leader-stat-chips'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.paperLine),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableStats.map((String statType) {
                  final bool selected = statType == activeStat;
                  return ChoiceChip(
                    label: Text(_shortLabelForStat(statType)),
                    selected: selected,
                    onSelected: (_) => onStatChanged(statType),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            if (twoColumn)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: _FeaturedLeadersSection(
                      statType: activeStat,
                      leaders: featured,
                      dashboard: dashboard,
                      brandingByAbbreviation: brandingByAbbreviation,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _LeaderListCard(
                      statType: activeStat,
                      leaders: remaining.isEmpty ? featured : remaining,
                      dashboard: dashboard,
                      brandingByAbbreviation: brandingByAbbreviation,
                      listOffset: remaining.isEmpty ? 0 : featured.length,
                    ),
                  ),
                ],
              )
            else ...<Widget>[
              _FeaturedLeadersSection(
                statType: activeStat,
                leaders: featured,
                dashboard: dashboard,
                brandingByAbbreviation: brandingByAbbreviation,
              ),
              const SizedBox(height: 16),
              _LeaderListCard(
                statType: activeStat,
                leaders: remaining.isEmpty ? featured : remaining,
                dashboard: dashboard,
                brandingByAbbreviation: brandingByAbbreviation,
                listOffset: remaining.isEmpty ? 0 : featured.length,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FeaturedLeadersSection extends StatelessWidget {
  const _FeaturedLeadersSection({
    required this.statType,
    required this.leaders,
    required this.dashboard,
    required this.brandingByAbbreviation,
  });

  final String statType;
  final List<PlayerLeader> leaders;
  final StatsDashboard dashboard;
  final Map<String, TeamBranding> brandingByAbbreviation;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('stats-featured-leaders'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _labelForStat(statType),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Top performers this season in ${_shortLabelForStat(statType)}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: leaders.map((PlayerLeader leader) {
              final TeamBranding? branding = _brandingForLeader(
                leader,
                dashboard,
                brandingByAbbreviation,
              );
              final String teamAbbreviation =
                  dashboard.teamsById[leader.player.teamId]?.abbreviation ??
                  'NBA';

              return SizedBox(
                width: 230,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.white,
                        (branding?.primaryColorValue != null
                                ? Color(branding!.primaryColorValue!)
                                : AppTheme.nbaBlue)
                            .withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          (branding?.primaryColorValue != null
                                  ? Color(branding!.primaryColorValue!)
                                  : AppTheme.nbaBlue)
                              .withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#${leader.rank}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          TeamLogoBadge(
                            abbreviation: teamAbbreviation,
                            teamName: teamAbbreviation,
                            branding: branding,
                            size: 42,
                            borderRadius: 14,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  leader.player.fullName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$teamAbbreviation • ${leader.player.position.isEmpty ? 'NBA' : leader.player.position}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _valueWithUnit(statType, leader.value),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontSize: 34,
                              color: branding?.primaryColorValue != null
                                  ? Color(branding!.primaryColorValue!)
                                  : AppTheme.nbaBlue,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${leader.gamesPlayed} GP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LeaderListCard extends StatelessWidget {
  const _LeaderListCard({
    required this.statType,
    required this.leaders,
    required this.dashboard,
    required this.brandingByAbbreviation,
    required this.listOffset,
  });

  final String statType;
  final List<PlayerLeader> leaders;
  final StatsDashboard dashboard;
  final Map<String, TeamBranding> brandingByAbbreviation;
  final int listOffset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_shortLabelForStat(statType)} Rankings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Ranked by per-game production.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ...leaders.asMap().entries.map((MapEntry<int, PlayerLeader> entry) {
              final PlayerLeader leader = entry.value;
              final TeamBranding? branding = _brandingForLeader(
                leader,
                dashboard,
                brandingByAbbreviation,
              );
              final String teamAbbreviation =
                  dashboard.teamsById[leader.player.teamId]?.abbreviation ??
                  'NBA';
              final Color accent = branding?.primaryColorValue != null
                  ? Color(branding!.primaryColorValue!)
                  : AppTheme.nbaBlue;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == leaders.length - 1 ? 0 : 12,
                ),
                child: Container(
                  key: Key(
                    'stats-leader-row-$statType-${entry.key + listOffset + 1}',
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#${leader.rank}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TeamLogoBadge(
                        abbreviation: teamAbbreviation,
                        teamName: teamAbbreviation,
                        branding: branding,
                        size: 42,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              leader.player.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$teamAbbreviation • ${leader.gamesPlayed} GP'
                              '${leader.player.position.isNotEmpty ? ' • ${leader.player.position}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _valueWithUnit(statType, leader.value),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: accent),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatsStateCard extends StatelessWidget {
  const _StatsStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 36, color: AppTheme.accentRed),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (showProgress) ...<Widget>[
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  onAction?.call();
                },
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsViewData {
  const _StatsViewData({
    required this.dashboard,
    required this.brandingByAbbreviation,
  });

  final StatsDashboard dashboard;
  final Map<String, TeamBranding> brandingByAbbreviation;
}

TeamBranding? _brandingForLeader(
  PlayerLeader leader,
  StatsDashboard dashboard,
  Map<String, TeamBranding> brandingByAbbreviation,
) {
  final String? abbreviation = dashboard
      .teamsById[leader.player.teamId]
      ?.abbreviation
      .toUpperCase();
  if (abbreviation == null) {
    return null;
  }
  return brandingByAbbreviation[abbreviation];
}

String _seasonLabel(int season) {
  return '$season-${(season + 1).toString().substring(2)}';
}

String _labelForStat(String statType) {
  switch (statType) {
    case 'pts':
      return 'Points Leaders';
    case 'reb':
      return 'Rebounds Leaders';
    case 'ast':
      return 'Assist Leaders';
    case 'stl':
      return 'Steals Leaders';
    case 'blk':
      return 'Blocks Leaders';
    default:
      return statType.toUpperCase();
  }
}

String _shortLabelForStat(String statType) {
  switch (statType) {
    case 'pts':
      return 'PTS';
    case 'reb':
      return 'REB';
    case 'ast':
      return 'AST';
    case 'stl':
      return 'STL';
    case 'blk':
      return 'BLK';
    default:
      return statType.toUpperCase();
  }
}

String _valueWithUnit(String statType, double value) {
  switch (statType) {
    case 'pts':
      return '${value.toStringAsFixed(1)} PPG';
    case 'reb':
      return '${value.toStringAsFixed(1)} RPG';
    case 'ast':
      return '${value.toStringAsFixed(1)} APG';
    case 'stl':
      return '${value.toStringAsFixed(1)} SPG';
    case 'blk':
      return '${value.toStringAsFixed(1)} BPG';
    default:
      return value.toStringAsFixed(1);
  }
}

String _winPctLabel(TeamStanding standing) {
  final int totalGames = standing.wins + standing.losses;
  if (totalGames == 0) {
    return '—';
  }

  final String label = (standing.wins / totalGames).toStringAsFixed(3);
  return label.startsWith('0') ? label.substring(1) : label;
}
