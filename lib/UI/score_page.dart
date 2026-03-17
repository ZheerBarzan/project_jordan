import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/repositories/basketball_repository.dart';
import 'package:project_jordan/theme/app_theme.dart';

enum _ScoreboardWindow { today, recent, custom }

class ScorePage extends StatefulWidget {
  ScorePage({super.key, BasketballDataRepository? repository})
      : repository = repository ?? BasketballRepository();

  final BasketballDataRepository repository;

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late Future<List<Game>> _futureGames;
  _ScoreboardWindow _window = _ScoreboardWindow.today;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _futureGames = widget.repository.fetchGamesForDate(_selectedDate);
  }

  Future<void> _loadGames() async {
    setState(() {
      switch (_window) {
        case _ScoreboardWindow.today:
          _selectedDate = DateTime.now();
          _futureGames = widget.repository.fetchGamesForDate(_selectedDate);
          break;
        case _ScoreboardWindow.recent:
          _futureGames = widget.repository.fetchRecentGames();
          break;
        case _ScoreboardWindow.custom:
          _futureGames = widget.repository.fetchGamesForDate(_selectedDate);
          break;
      }
    });
    await _futureGames;
  }

  Future<void> _pickCustomDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate == null) {
      return;
    }

    setState(() {
      _window = _ScoreboardWindow.custom;
      _selectedDate = pickedDate;
      _futureGames = widget.repository.fetchGamesForDate(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Game>>(
      future: _futureGames,
      builder: (BuildContext context, AsyncSnapshot<List<Game>> snapshot) {
        return RefreshIndicator(
          color: AppTheme.accentRed,
          onRefresh: _loadGames,
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
                      _ScoreFilters(
                        currentWindow: _window,
                        selectedDate: _selectedDate,
                        onWindowChanged: (_ScoreboardWindow window) {
                          setState(() {
                            _window = window;
                          });
                          _loadGames();
                        },
                        onPickCustomDate: _pickCustomDate,
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
    AsyncSnapshot<List<Game>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _CenteredState(
        icon: Icons.sports_basketball_outlined,
        title: 'Loading scoreboard',
        message: 'Pulling the latest NBA game slate and statuses.',
        showProgress: true,
      );
    }

    if (snapshot.hasError) {
      return _CenteredState(
        icon: Icons.error_outline,
        title: 'Scoreboard unavailable',
        message: snapshot.error.toString(),
        actionLabel: 'Retry',
        onAction: _loadGames,
      );
    }

    final List<Game> games = snapshot.data ?? <Game>[];
    if (games.isEmpty) {
      return _CenteredState(
        icon: Icons.event_busy_outlined,
        title: 'No games found',
        message:
            'There are no NBA games in this window. Try another date or switch back to recent games.',
        actionLabel: 'Refresh',
        onAction: _loadGames,
      );
    }

    final LinkedHashMap<DateTime, List<Game>> groupedGames = _groupGamesByDate(games);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedGames.entries.map((MapEntry<DateTime, List<Game>> entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DateFormat('EEEE, MMM d').format(entry.key),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              ...entry.value.map((Game game) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GameCard(game: game),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  LinkedHashMap<DateTime, List<Game>> _groupGamesByDate(List<Game> games) {
    final LinkedHashMap<DateTime, List<Game>> grouped = LinkedHashMap<DateTime, List<Game>>();
    for (final Game game in games) {
      final DateTime key = DateTime(
        game.parsedDate.year,
        game.parsedDate.month,
        game.parsedDate.day,
      );
      grouped.putIfAbsent(key, () => <Game>[]).add(game);
    }
    return grouped;
  }
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
          colors: <Color>[
            AppTheme.nbaBlue,
            AppTheme.courtBlue,
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
              'League Scoreboard',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Today, recent slates, and game-day status cards ordered for quick scanning.',
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

class _ScoreFilters extends StatelessWidget {
  const _ScoreFilters({
    required this.currentWindow,
    required this.selectedDate,
    required this.onWindowChanged,
    required this.onPickCustomDate,
  });

  final _ScoreboardWindow currentWindow;
  final DateTime selectedDate;
  final ValueChanged<_ScoreboardWindow> onWindowChanged;
  final VoidCallback onPickCustomDate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ChoiceChip(
          label: const Text('Today'),
          selected: currentWindow == _ScoreboardWindow.today,
          onSelected: (_) => onWindowChanged(_ScoreboardWindow.today),
        ),
        ChoiceChip(
          label: const Text('Recent'),
          selected: currentWindow == _ScoreboardWindow.recent,
          onSelected: (_) => onWindowChanged(_ScoreboardWindow.recent),
        ),
        OutlinedButton.icon(
          onPressed: onPickCustomDate,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(
            currentWindow == _ScoreboardWindow.custom
                ? DateFormat('MMM d').format(selectedDate)
                : 'Pick date',
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _StatusBadge(game: game),
                const Spacer(),
                if (game.postseason)
                  Text(
                    'POSTSEASON',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.accentRed,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            _TeamScoreRow(
              abbreviation: game.visitorTeam.abbreviation,
              teamName: game.visitorTeam.fullName,
              score: game.visitorTeamScore,
              emphasize: game.visitorTeamScore > game.homeTeamScore,
            ),
            const SizedBox(height: 14),
            _TeamScoreRow(
              abbreviation: game.homeTeam.abbreviation,
              teamName: game.homeTeam.fullName,
              score: game.homeTeamScore,
              emphasize: game.homeTeamScore >= game.visitorTeamScore,
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _detailText(game),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  'Season ${game.season}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _detailText(Game game) {
    if (game.postponed) {
      return 'Postponed';
    }
    if (game.isLive) {
      if (game.status == 'Halftime') {
        return 'Halftime';
      }
      return 'Live • ${game.status}';
    }
    if (game.isFinal) {
      return 'Final • ${DateFormat('h:mm a').format(game.parsedDate)} tip-off';
    }
    return 'Scheduled • ${DateFormat('h:mm a').format(game.parsedDate)}';
  }
}

class _TeamScoreRow extends StatelessWidget {
  const _TeamScoreRow({
    required this.abbreviation,
    required this.teamName,
    required this.score,
    required this.emphasize,
  });

  final String abbreviation;
  final String teamName;
  final int score;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final TextStyle? scoreStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 38,
          color: emphasize ? AppTheme.accentRed : AppTheme.nbaBlue,
        );

    return Row(
      children: <Widget>[
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppTheme.nbaBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Text(
            abbreviation,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.nbaBlue,
                ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(teamName, style: Theme.of(context).textTheme.titleLarge),
              Text(
                abbreviation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text('$score', style: scoreStyle),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, String label) = switch (true) {
      _ when game.isLive => (
          AppTheme.accentRed,
          Colors.white,
          'LIVE',
        ),
      _ when game.isFinal => (
          AppTheme.nbaBlue.withValues(alpha: 0.12),
          AppTheme.nbaBlue,
          'FINAL',
        ),
      _ when game.postponed => (
          Colors.orange.shade100,
          Colors.orange.shade900,
          'POSTPONED',
        ),
      _ => (
          Colors.green.shade100,
          Colors.green.shade900,
          'UPCOMING',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
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
