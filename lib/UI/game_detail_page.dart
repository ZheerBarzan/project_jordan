import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/components/team_logo_badge.dart';
import 'package:project_jordan/model/game_detail.dart';
import 'package:project_jordan/model/team_branding.dart';
import 'package:project_jordan/theme/app_theme.dart';

class GameDetailPage extends StatefulWidget {
  const GameDetailPage({
    super.key,
    required this.detail,
    this.homeBranding,
    this.visitorBranding,
  });

  final GameDetail detail;
  final TeamBranding? homeBranding;
  final TeamBranding? visitorBranding;

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Game Detail',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 22),
        ),
      ),
      body: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _HeroPanel(
                    detail: widget.detail,
                    homeBranding: widget.homeBranding,
                    visitorBranding: widget.visitorBranding,
                  ),
                  const SizedBox(height: 14),
                  _InfoStrip(detail: widget.detail),
                  if (widget.detail.hasSummary) ...<Widget>[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Matchup Summary',
                      child: Text(
                        widget.detail.summary!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                  if (widget.detail.hasLineScore) ...<Widget>[
                    const SizedBox(height: 14),
                    _LineScoreCard(
                      detail: widget.detail,
                      homeBranding: widget.homeBranding,
                      visitorBranding: widget.visitorBranding,
                    ),
                  ],
                  if (widget.detail.hasNotes) ...<Widget>[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: widget.detail.game.isScheduled
                          ? 'Preview Notes'
                          : 'Game Notes',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.detail.notes
                            .map(
                              (String note) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.detail,
    required this.homeBranding,
    required this.visitorBranding,
  });

  final GameDetail detail;
  final TeamBranding? homeBranding;
  final TeamBranding? visitorBranding;

  @override
  Widget build(BuildContext context) {
    final Color left = _brandColor(
      visitorBranding,
      fallback: AppTheme.courtBlue,
    );
    final Color right = _brandColor(homeBranding, fallback: AppTheme.nbaBlue);
    final String headline = detail.headline?.trim().isNotEmpty == true
        ? detail.headline!
        : '${detail.game.visitorTeam.name} at ${detail.game.homeTeam.name}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[left, right],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stacked = constraints.maxWidth < 720;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                headline,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: stacked ? 29 : 38,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _heroSubtitle(detail),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              stacked
                  ? Column(
                      children: <Widget>[
                        _HeroTeam(
                          alignment: CrossAxisAlignment.center,
                          teamName: detail.game.visitorTeam.fullName,
                          abbreviation: detail.game.visitorTeam.abbreviation,
                          score: detail.game.isScheduled
                              ? null
                              : detail.game.visitorTeamScore,
                          branding: visitorBranding,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: _CenterStatus(detail: detail, compact: true),
                        ),
                        _HeroTeam(
                          alignment: CrossAxisAlignment.center,
                          teamName: detail.game.homeTeam.fullName,
                          abbreviation: detail.game.homeTeam.abbreviation,
                          score: detail.game.isScheduled
                              ? null
                              : detail.game.homeTeamScore,
                          branding: homeBranding,
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: _HeroTeam(
                            alignment: CrossAxisAlignment.start,
                            teamName: detail.game.visitorTeam.fullName,
                            abbreviation: detail.game.visitorTeam.abbreviation,
                            score: detail.game.isScheduled
                                ? null
                                : detail.game.visitorTeamScore,
                            branding: visitorBranding,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: _CenterStatus(detail: detail),
                        ),
                        Expanded(
                          child: _HeroTeam(
                            alignment: CrossAxisAlignment.end,
                            teamName: detail.game.homeTeam.fullName,
                            abbreviation: detail.game.homeTeam.abbreviation,
                            score: detail.game.isScheduled
                                ? null
                                : detail.game.homeTeamScore,
                            branding: homeBranding,
                          ),
                        ),
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }

  String _heroSubtitle(GameDetail detail) {
    final String formattedDate = DateFormat(
      'EEEE, MMM d • h:mm a',
    ).format(detail.game.parsedDate);
    final String status = switch (true) {
      _ when detail.game.postponed => 'Postponed',
      _ when detail.game.isLive => 'Live • ${detail.game.status}',
      _ when detail.game.isFinal => 'Final',
      _ => 'Scheduled',
    };

    return '$formattedDate • $status';
  }

  Color _brandColor(TeamBranding? branding, {required Color fallback}) {
    final int? colorValue = branding?.primaryColorValue;
    return colorValue == null ? fallback : Color(colorValue);
  }
}

class _HeroTeam extends StatelessWidget {
  const _HeroTeam({
    required this.alignment,
    required this.teamName,
    required this.abbreviation,
    required this.score,
    required this.branding,
  });

  final CrossAxisAlignment alignment;
  final String teamName;
  final String abbreviation;
  final int? score;
  final TeamBranding? branding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        TeamLogoBadge(
          abbreviation: abbreviation,
          teamName: teamName,
          branding: branding,
          size: 68,
          borderRadius: 22,
        ),
        const SizedBox(height: 10),
        Text(
          teamName,
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : alignment == CrossAxisAlignment.end
              ? TextAlign.end
              : TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          abbreviation,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          score == null ? 'VS' : '$score',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: Colors.white, fontSize: 40),
        ),
      ],
    );
  }
}

class _CenterStatus extends StatelessWidget {
  const _CenterStatus({required this.detail, this.compact = false});

  final GameDetail detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String label = switch (true) {
      _ when detail.game.postponed => 'POSTPONED',
      _ when detail.game.isLive => 'LIVE',
      _ when detail.game.isFinal => 'FINAL',
      _ => 'TIPOFF',
    };

    final String supporting = switch (true) {
      _ when detail.game.postponed => detail.game.time,
      _ when detail.game.isLive => detail.game.status,
      _ when detail.game.isFinal => 'Season ${detail.game.season}',
      _ => DateFormat('h:mm a').format(detail.game.parsedDate),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            supporting,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.detail});

  final GameDetail detail;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = <String>[
      'Season ${detail.game.season}',
      if (detail.hasVenue) detail.arena!,
      if (detail.hasLocation) detail.location!,
      if (detail.game.postseason) 'Postseason',
      if (detail.game.postponed) 'Postponed',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: labels
          .map(
            (String label) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.paperLine),
              ),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 12),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _LineScoreCard extends StatelessWidget {
  const _LineScoreCard({
    required this.detail,
    required this.homeBranding,
    required this.visitorBranding,
  });

  final GameDetail detail;
  final TeamBranding? homeBranding;
  final TeamBranding? visitorBranding;

  @override
  Widget build(BuildContext context) {
    final int quarterCount =
        detail.homeLineScores.length > detail.visitorLineScores.length
        ? detail.homeLineScores.length
        : detail.visitorLineScores.length;

    return _SectionCard(
      title: 'Line Score',
      child: Table(
        columnWidths: <int, TableColumnWidth>{
          0: const FlexColumnWidth(2.4),
          for (int i = 1; i <= quarterCount; i += 1) i: const FlexColumnWidth(),
          quarterCount + 1: const FlexColumnWidth(1.1),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          TableRow(
            children: <Widget>[
              const SizedBox(height: 28),
              ...List<Widget>.generate(
                quarterCount,
                (int index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Q${index + 1}',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(fontSize: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'T',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          _lineRow(
            context,
            teamName: detail.game.visitorTeam.name,
            abbreviation: detail.game.visitorTeam.abbreviation,
            branding: visitorBranding,
            scores: detail.visitorLineScores,
            total: detail.game.visitorTeamScore,
          ),
          _lineRow(
            context,
            teamName: detail.game.homeTeam.name,
            abbreviation: detail.game.homeTeam.abbreviation,
            branding: homeBranding,
            scores: detail.homeLineScores,
            total: detail.game.homeTeamScore,
          ),
        ],
      ),
    );
  }

  TableRow _lineRow(
    BuildContext context, {
    required String teamName,
    required String abbreviation,
    required TeamBranding? branding,
    required List<int> scores,
    required int total,
  }) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              TeamLogoBadge(
                abbreviation: abbreviation,
                teamName: teamName,
                branding: branding,
                size: 32,
                borderRadius: 12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        ...scores.map(
          (int score) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '$score',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 14),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            '$total',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.accentRed,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
