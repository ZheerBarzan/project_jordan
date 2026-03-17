import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/model/player_leader.dart';
import 'package:project_jordan/model/stats_dashboard.dart';
import 'package:project_jordan/model/team_season_stats.dart';
import 'package:project_jordan/model/team_standing.dart';
import 'package:project_jordan/repositories/basketball_repository.dart';
import 'package:project_jordan/theme/app_theme.dart';

enum _StatsSection { teams, players }

class StatsPage extends StatefulWidget {
  StatsPage({super.key, BasketballDataRepository? repository})
      : repository = repository ?? BasketballRepository();

  final BasketballDataRepository repository;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<StatsDashboard> _futureDashboard;
  late final int _season = _currentNbaSeason(DateTime.now());
  _StatsSection _section = _StatsSection.teams;

  @override
  void initState() {
    super.initState();
    _futureDashboard = widget.repository.fetchStatsDashboard(season: _season);
  }

  Future<void> _reload() async {
    setState(() {
      _futureDashboard = widget.repository.fetchStatsDashboard(season: _season);
    });
    await _futureDashboard;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatsDashboard>(
      future: _futureDashboard,
      builder:
          (BuildContext context, AsyncSnapshot<StatsDashboard> snapshot) {
        return RefreshIndicator(
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
                      _StatsHeader(season: _season),
                      const SizedBox(height: 18),
                      _StatsToolbar(
                        currentSection: _section,
                        season: _season,
                        onSectionChanged: (_StatsSection section) {
                          setState(() {
                            _section = section;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildBody(context, snapshot),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<StatsDashboard> snapshot,
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

    final StatsDashboard dashboard = snapshot.data!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (dashboard.warnings.isNotEmpty) ...<Widget>[
          _WarningBanner(messages: dashboard.warnings),
          const SizedBox(height: 16),
        ],
        if (_section == _StatsSection.teams)
          _TeamsDashboard(dashboard: dashboard)
        else
          _PlayersDashboard(dashboard: dashboard),
      ],
    );
  }

  int _currentNbaSeason(DateTime now) {
    return now.month >= 10 ? now.year : now.year - 1;
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.season});

  final int season;

  @override
  Widget build(BuildContext context) {
    final String seasonLabel = '$season-${(season + 1).toString().substring(2)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.courtBlue,
            AppTheme.nbaBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Stats Dashboard',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Conference standings, team season numbers, and player leaderboards for $seasonLabel.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsToolbar extends StatelessWidget {
  const _StatsToolbar({
    required this.currentSection,
    required this.season,
    required this.onSectionChanged,
  });

  final _StatsSection currentSection;
  final int season;
  final ValueChanged<_StatsSection> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    final String seasonLabel = '$season-${(season + 1).toString().substring(2)}';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SegmentedButton<_StatsSection>(
          segments: const <ButtonSegment<_StatsSection>>[
            ButtonSegment<_StatsSection>(
              value: _StatsSection.teams,
              label: Text('Teams'),
              icon: Icon(Icons.bar_chart_rounded),
            ),
            ButtonSegment<_StatsSection>(
              value: _StatsSection.players,
              label: Text('Players'),
              icon: Icon(Icons.person_rounded),
            ),
          ],
          selected: <_StatsSection>{currentSection},
          onSelectionChanged: (Set<_StatsSection> selection) {
            onSectionChanged(selection.first);
          },
        ),
        Chip(
          avatar: const Icon(Icons.lock_clock_rounded, size: 18),
          label: Text('Season $seasonLabel'),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade900),
                const SizedBox(width: 8),
                Text(
                  'Partial Data',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...messages.map(
              (String message) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $message',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamsDashboard extends StatelessWidget {
  const _TeamsDashboard({required this.dashboard});

  final StatsDashboard dashboard;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ConferenceOverview(east: east, west: west),
        const SizedBox(height: 20),
        _ConferenceSection(
          title: 'Eastern Conference',
          standings: east,
          dashboard: dashboard,
        ),
        const SizedBox(height: 20),
        _ConferenceSection(
          title: 'Western Conference',
          standings: west,
          dashboard: dashboard,
        ),
      ],
    );
  }
}

class _ConferenceOverview extends StatelessWidget {
  const _ConferenceOverview({required this.east, required this.west});

  final List<TeamStanding> east;
  final List<TeamStanding> west;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth =
            constraints.maxWidth > 900 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            SizedBox(
              width: cardWidth,
              child: _ConferenceSummaryCard(
                title: 'East Snapshot',
                standings: east,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ConferenceSummaryCard(
                title: 'West Snapshot',
                standings: west,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConferenceSummaryCard extends StatelessWidget {
  const _ConferenceSummaryCard({
    required this.title,
    required this.standings,
  });

  final String title;
  final List<TeamStanding> standings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ...standings.take(3).map((TeamStanding standing) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    Text(
                      '#${standing.conferenceRank}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.accentRed,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        standing.team.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${standing.wins}-${standing.losses}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ConferenceSection extends StatelessWidget {
  const _ConferenceSection({
    required this.title,
    required this.standings,
    required this.dashboard,
  });

  final String title;
  final List<TeamStanding> standings;
  final StatsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth =
            constraints.maxWidth > 720 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: standings.map((TeamStanding standing) {
                return SizedBox(
                  width: cardWidth,
                  child: _TeamStandingCard(
                    standing: standing,
                    stats: dashboard.teamStatsById[standing.team.id],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _TeamStandingCard extends StatelessWidget {
  const _TeamStandingCard({required this.standing, this.stats});

  final TeamStanding standing;
  final TeamSeasonStats? stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.nbaBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    standing.team.abbreviation,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.nbaBlue,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        standing.team.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '#${standing.conferenceRank} in ${standing.team.conference}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${standing.wins}-${standing.losses}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.accentRed,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MiniStat(label: 'Home', value: standing.homeRecord),
                _MiniStat(label: 'Road', value: standing.roadRecord),
                _MiniStat(label: 'Conf', value: standing.conferenceRecord),
                _MiniStat(label: 'Div', value: standing.divisionRecord),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MiniStat(
                  label: 'PPG',
                  value: stats != null ? stats!.points.toStringAsFixed(1) : '—',
                ),
                _MiniStat(
                  label: 'RPG',
                  value:
                      stats != null ? stats!.rebounds.toStringAsFixed(1) : '—',
                ),
                _MiniStat(
                  label: 'APG',
                  value:
                      stats != null ? stats!.assists.toStringAsFixed(1) : '—',
                ),
                _MiniStat(
                  label: 'FG%',
                  value: stats != null
                      ? NumberFormat.percentPattern()
                          .format(stats!.fieldGoalPct / 100)
                      : '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.nbaBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _PlayersDashboard extends StatelessWidget {
  const _PlayersDashboard({required this.dashboard});

  final StatsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    if (dashboard.leadersByStat.isEmpty) {
      return const _StatsStateCard(
        icon: Icons.person_search_outlined,
        title: 'No player leaderboards available',
        message:
            'Player leaderboards need BallDontLie access to the leaders endpoint.',
      );
    }

    final List<MapEntry<String, List<PlayerLeader>>> leaderboards =
        dashboard.leadersByStat.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth =
            constraints.maxWidth > 900 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: leaderboards.map((MapEntry<String, List<PlayerLeader>> entry) {
            return SizedBox(
              width: cardWidth,
              child: _LeaderboardCard(
                statType: entry.key,
                leaders: entry.value,
                dashboard: dashboard,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.statType,
    required this.leaders,
    required this.dashboard,
  });

  final String statType;
  final List<PlayerLeader> leaders;
  final StatsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_labelForStat(statType), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ...leaders.take(5).map((PlayerLeader leader) {
              final String teamAbbreviation =
                  dashboard.teamsById[leader.player.teamId]?.abbreviation ?? 'NBA';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 38,
                      child: Text(
                        '#${leader.rank}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.accentRed,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            leader.player.fullName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '$teamAbbreviation • ${leader.gamesPlayed} GP',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      leader.value.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.nbaBlue,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
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
