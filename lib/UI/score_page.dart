import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/UI/game_detail_page.dart';
import 'package:project_jordan/components/scroll_chrome.dart';
import 'package:project_jordan/components/team_logo_badge.dart';
import 'package:project_jordan/model/game_detail.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/team_branding.dart';
import 'package:project_jordan/repositories/basketball_repository.dart';
import 'package:project_jordan/repositories/fallback_aware_repository.dart';
import 'package:project_jordan/repositories/scoreboard_content_repository.dart';
import 'package:project_jordan/theme/app_theme.dart';

enum _ScoreboardSegment { upcoming, previous }

class ScorePage extends StatefulWidget {
  ScorePage({
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
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  static const int _upcomingWindowDays = 7;
  static const int _previousWindowDays = 14;

  late Future<_ScorePageData> _futureData;
  _ScoreboardSegment _segment = _ScoreboardSegment.upcoming;

  @override
  void initState() {
    super.initState();
    _futureData = _loadData();
  }

  Future<_ScorePageData> _loadData() async {
    final List<Game> games = await _loadGamesForSegment();
    final Map<String, TeamBranding> brandingByAbbreviation =
        await widget.contentRepository.loadTeamBranding();
    final Map<int, Map<String, dynamic>> enrichmentByGameId =
        await widget.contentRepository.loadGameDetailEnrichment();

    return _ScorePageData(
      games: games,
      brandingByAbbreviation: brandingByAbbreviation,
      detailEnrichmentByGameId: enrichmentByGameId,
    );
  }

  Future<List<Game>> _loadGamesForSegment() {
    switch (_segment) {
      case _ScoreboardSegment.upcoming:
        return widget.repository.fetchUpcomingGames(days: _upcomingWindowDays);
      case _ScoreboardSegment.previous:
        return widget.repository.fetchPreviousGames(days: _previousWindowDays);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureData = _loadData();
    });
    await _futureData;
  }

  void _changeSegment(_ScoreboardSegment segment) {
    if (_segment == segment) {
      return;
    }

    setState(() {
      _segment = segment;
      _futureData = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ScorePageData>(
      future: _futureData,
      builder: (BuildContext context, AsyncSnapshot<_ScorePageData> snapshot) {
        return NotificationListener<UserScrollNotification>(
          onNotification: _handleScrollNotification,
          child: RefreshIndicator(
            color: AppTheme.accentRed,
            onRefresh: _refresh,
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
                        const _ScoreHeader(),
                        const SizedBox(height: 18),
                        _SegmentSelector(
                          selectedSegment: _segment,
                          onSelectionChanged: _changeSegment,
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
    AsyncSnapshot<_ScorePageData> snapshot,
  ) {
    final bool isUsingFallbackData =
        widget.repository is FallbackAwareRepository &&
        (widget.repository as FallbackAwareRepository)
            .isUsingFallbackData
            .value;

    if (snapshot.connectionState == ConnectionState.waiting) {
      return _CenteredState(
        icon: Icons.sports_basketball_outlined,
        title: 'Loading ${_segment.label.toLowerCase()} games',
        message: _segment == _ScoreboardSegment.upcoming
            ? 'Building the next week of NBA matchups.'
            : 'Pulling recent results and final statuses.',
        showProgress: true,
      );
    }

    if (snapshot.hasError) {
      return _CenteredState(
        icon: Icons.error_outline,
        title: 'Scoreboard unavailable',
        message: snapshot.error.toString(),
        actionLabel: 'Retry',
        onAction: _refresh,
      );
    }

    final _ScorePageData data = snapshot.data!;
    if (data.games.isEmpty) {
      return _CenteredState(
        icon: Icons.event_busy_outlined,
        title: _segment == _ScoreboardSegment.upcoming
            ? 'No upcoming games found'
            : 'No previous games found',
        message: _segment == _ScoreboardSegment.upcoming
            ? 'There are no scheduled or live NBA games in the next 7 days.'
            : 'There are no completed NBA games in the last 14 days.',
        actionLabel: 'Refresh',
        onAction: _refresh,
      );
    }

    final LinkedHashMap<DateTime, List<GameDetail>> groupedGames =
        _groupGamesByDate(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (isUsingFallbackData) ...<Widget>[
          const _FallbackBanner(
            message:
                'Showing bundled demo scoreboard data because live NBA scores are unavailable right now.',
          ),
          const SizedBox(height: 16),
        ],
        _SegmentOverview(segment: _segment, totalGames: data.games.length),
        const SizedBox(height: 16),
        ...groupedGames.entries.map((MapEntry<DateTime, List<GameDetail>> entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _sectionLabel(entry.key),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                ...entry.value.map(
                  (GameDetail detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GameCard(
                      key: ValueKey<int>(detail.game.id),
                      detail: detail,
                      homeBranding: data.brandingByAbbreviation[
                          detail.game.homeTeam.abbreviation.toUpperCase()],
                      visitorBranding: data.brandingByAbbreviation[
                          detail.game.visitorTeam.abbreviation.toUpperCase()],
                      onTap: () => _openGameDetail(context, data, detail),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  LinkedHashMap<DateTime, List<GameDetail>> _groupGamesByDate(
    _ScorePageData data,
  ) {
    final LinkedHashMap<DateTime, List<GameDetail>> grouped =
        LinkedHashMap<DateTime, List<GameDetail>>();

    for (final Game game in data.games) {
      final DateTime key = DateTime(
        game.parsedDate.year,
        game.parsedDate.month,
        game.parsedDate.day,
      );
      final GameDetail detail = widget.contentRepository.buildGameDetail(
        game,
        data.detailEnrichmentByGameId,
      );
      grouped.putIfAbsent(key, () => <GameDetail>[]).add(detail);
    }

    return grouped;
  }

  void _openGameDetail(
    BuildContext context,
    _ScorePageData data,
    GameDetail detail,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GameDetailPage(
          detail: detail,
          homeBranding: data.brandingByAbbreviation[
              detail.game.homeTeam.abbreviation.toUpperCase()],
          visitorBranding: data.brandingByAbbreviation[
              detail.game.visitorTeam.abbreviation.toUpperCase()],
        ),
      ),
    );
  }

  String _sectionLabel(DateTime date) {
    final DateTime today = DateTime.now();
    final DateTime normalizedToday =
        DateTime(today.year, today.month, today.day);
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    final int difference = normalizedDate.difference(normalizedToday).inDays;

    switch (difference) {
      case 0:
        return 'Today • ${DateFormat('EEEE, MMM d').format(date)}';
      case 1:
        return 'Tomorrow • ${DateFormat('EEEE, MMM d').format(date)}';
      case -1:
        return 'Yesterday • ${DateFormat('EEEE, MMM d').format(date)}';
      default:
        return DateFormat('EEEE, MMM d').format(date);
    }
  }
}

class _ScorePageData {
  const _ScorePageData({
    required this.games,
    required this.brandingByAbbreviation,
    required this.detailEnrichmentByGameId,
  });

  final List<Game> games;
  final Map<String, TeamBranding> brandingByAbbreviation;
  final Map<int, Map<String, dynamic>> detailEnrichmentByGameId;
}

extension on _ScoreboardSegment {
  String get label => switch (this) {
    _ScoreboardSegment.upcoming => 'Upcoming',
    _ScoreboardSegment.previous => 'Previous',
  };
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppTheme.nbaBlue, AppTheme.courtBlue],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'League Game Center',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Upcoming matchups, recent results, and richer game cards with team branding and deeper detail screens.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentSelector extends StatelessWidget {
  const _SegmentSelector({
    required this.selectedSegment,
    required this.onSelectionChanged,
  });

  final _ScoreboardSegment selectedSegment;
  final ValueChanged<_ScoreboardSegment> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_ScoreboardSegment>(
      showSelectedIcon: false,
      segments: const <ButtonSegment<_ScoreboardSegment>>[
        ButtonSegment<_ScoreboardSegment>(
          value: _ScoreboardSegment.upcoming,
          label: Text('Upcoming'),
          icon: Icon(Icons.upcoming_rounded),
        ),
        ButtonSegment<_ScoreboardSegment>(
          value: _ScoreboardSegment.previous,
          label: Text('Previous'),
          icon: Icon(Icons.history_rounded),
        ),
      ],
      selected: <_ScoreboardSegment>{selectedSegment},
      onSelectionChanged: (Set<_ScoreboardSegment> selection) {
        onSelectionChanged(selection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.accentRed;
            }
            return Colors.white;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppTheme.courtBlue;
          },
        ),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }
}

class _SegmentOverview extends StatelessWidget {
  const _SegmentOverview({
    required this.segment,
    required this.totalGames,
  });

  final _ScoreboardSegment segment;
  final int totalGames;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.nbaBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                segment == _ScoreboardSegment.upcoming
                    ? Icons.event_available_rounded
                    : Icons.scoreboard_outlined,
                color: AppTheme.nbaBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    segment == _ScoreboardSegment.upcoming
                        ? 'Next 7 days'
                        : 'Last 14 days',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    segment == _ScoreboardSegment.upcoming
                        ? 'Live games and scheduled matchups ordered to keep the next slate readable.'
                        : 'Completed results, finals, and recent status changes grouped by date.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              '$totalGames games',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.accentRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    super.key,
    required this.detail,
    required this.homeBranding,
    required this.visitorBranding,
    required this.onTap,
  });

  final GameDetail detail;
  final TeamBranding? homeBranding;
  final TeamBranding? visitorBranding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color visitorColor =
        _brandColor(visitorBranding, fallback: AppTheme.nbaBlue);
    final Color homeColor = _brandColor(homeBranding, fallback: AppTheme.courtBlue);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('score-card-${detail.game.id}'),
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[visitorColor, homeColor],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _StatusBadge(detail: detail),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('EEE • h:mm a').format(detail.game.parsedDate),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppTheme.courtBlue,
                      ),
                    ],
                  ),
                  if ((detail.headline ?? '').trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      detail.headline!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _TeamRow(
                    teamName: detail.game.visitorTeam.fullName,
                    abbreviation: detail.game.visitorTeam.abbreviation,
                    branding: visitorBranding,
                    score: detail.game.isScheduled ? null : detail.game.visitorTeamScore,
                    emphasize: !detail.game.isScheduled &&
                        detail.game.visitorTeamScore > detail.game.homeTeamScore,
                    roleLabel: 'AWAY',
                  ),
                  const SizedBox(height: 14),
                  _TeamRow(
                    teamName: detail.game.homeTeam.fullName,
                    abbreviation: detail.game.homeTeam.abbreviation,
                    branding: homeBranding,
                    score: detail.game.isScheduled ? null : detail.game.homeTeamScore,
                    emphasize: !detail.game.isScheduled &&
                        detail.game.homeTeamScore >= detail.game.visitorTeamScore,
                    roleLabel: 'HOME',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _footerText(detail),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        detail.game.postseason ? 'POSTSEASON' : 'Season ${detail.game.season}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.accentRed,
                        ),
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

  String _footerText(GameDetail detail) {
    if (detail.game.postponed) {
      return 'Postponed${detail.hasVenue ? ' • ${detail.arena}' : ''}';
    }

    final String prefix = switch (true) {
      _ when detail.game.isLive => 'Live coverage',
      _ when detail.game.isFinal => 'Completed',
      _ => 'Preview',
    };

    final String suffix = detail.hasVenue
        ? detail.arena!
        : detail.hasLocation
            ? detail.location!
            : detail.game.homeTeam.city;
    return '$prefix • $suffix';
  }

  Color _brandColor(TeamBranding? branding, {required Color fallback}) {
    final int? colorValue = branding?.primaryColorValue;
    return colorValue == null ? fallback : Color(colorValue);
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.teamName,
    required this.abbreviation,
    required this.branding,
    required this.score,
    required this.emphasize,
    required this.roleLabel,
  });

  final String teamName;
  final String abbreviation;
  final TeamBranding? branding;
  final int? score;
  final bool emphasize;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final Color accent = emphasize ? AppTheme.accentRed : AppTheme.nbaBlue;

    return Row(
      children: <Widget>[
        TeamLogoBadge(
          abbreviation: abbreviation,
          teamName: teamName,
          branding: branding,
          size: 60,
          borderRadius: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(teamName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(
                '$abbreviation • $roleLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        score == null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  roleLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                  ),
                ),
              )
            : Text(
                '$score',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 42,
                  color: accent,
                ),
              ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.detail});

  final GameDetail detail;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, String label) = switch (true) {
      _ when detail.game.isLive => (AppTheme.accentRed, Colors.white, 'LIVE'),
      _ when detail.game.isFinal => (
        AppTheme.nbaBlue.withValues(alpha: 0.12),
        AppTheme.nbaBlue,
        'FINAL',
      ),
      _ when detail.game.postponed => (
        Colors.orange.shade100,
        Colors.orange.shade900,
        'POSTPONED',
      ),
      _ => (Colors.green.shade100, Colors.green.shade900, 'UPCOMING'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: foreground),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
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
                  onAction!();
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

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.info_outline, color: Colors.orange.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
