import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/UI/article_reader_page.dart';
import 'package:project_jordan/components/scroll_chrome.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/repositories/fallback_aware_repository.dart';
import 'package:project_jordan/repositories/news_repository.dart';
import 'package:project_jordan/theme/app_theme.dart';

enum _NewsLayoutMode { list, grid }

typedef ArticleReaderBuilder =
    Widget Function(BuildContext context, Article article);

class NewsPage extends StatefulWidget {
  NewsPage({
    super.key,
    NewsFeedRepository? repository,
    this.onChromeVisibilityChanged,
    this.readerPageBuilder,
  }) : repository = repository ?? NewsRepository();

  final NewsFeedRepository repository;
  final ChromeVisibilityChanged? onChromeVisibilityChanged;
  final ArticleReaderBuilder? readerPageBuilder;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<Article>> _futureArticles;
  _NewsLayoutMode _layoutMode = _NewsLayoutMode.list;

  @override
  void initState() {
    super.initState();
    _futureArticles = widget.repository.fetchLatestNbaNews();
  }

  Future<void> _reload() async {
    setState(() {
      _futureArticles = widget.repository.fetchLatestNbaNews();
    });
    await _futureArticles;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: _futureArticles,
      builder: (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
        return NotificationListener<UserScrollNotification>(
          onNotification: _handleScrollNotification,
          child: RefreshIndicator(
            color: AppTheme.accentRed,
            onRefresh: _reload,
            child: Scrollbar(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: _buildBody(context, snapshot),
                    ),
                  ),
                ],
              ),
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
    AsyncSnapshot<List<Article>> snapshot,
  ) {
    final bool isUsingFallbackData =
        widget.repository is FallbackAwareRepository &&
        (widget.repository as FallbackAwareRepository)
            .isUsingFallbackData
            .value;

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _NewsToolbar(
            layoutMode: _layoutMode,
            onModeChanged: _setLayoutMode,
            isUsingFallbackData: false,
          ),
          const SizedBox(height: 18),
          const _NewsStateCard(
            icon: Icons.auto_stories_outlined,
            title: 'Loading the latest coverage',
            message:
                'Pulling fresh headlines from the live news wires and preparing the reading view.',
            showProgress: true,
          ),
        ],
      );
    }

    if (snapshot.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _NewsToolbar(
            layoutMode: _layoutMode,
            onModeChanged: _setLayoutMode,
            isUsingFallbackData: false,
          ),
          const SizedBox(height: 18),
          _NewsStateCard(
            icon: Icons.error_outline_rounded,
            title: 'News feed unavailable',
            message: snapshot.error.toString(),
            actionLabel: 'Retry',
            onAction: _reload,
          ),
        ],
      );
    }

    final List<Article> articles = snapshot.data ?? <Article>[];
    if (articles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _NewsToolbar(
            layoutMode: _layoutMode,
            onModeChanged: _setLayoutMode,
            isUsingFallbackData: false,
          ),
          const SizedBox(height: 18),
          _NewsStateCard(
            icon: Icons.newspaper_outlined,
            title: 'No stories right now',
            message:
                'The wire returned an empty feed. Pull to refresh and try again in a moment.',
            actionLabel: 'Refresh',
            onAction: _reload,
          ),
        ],
      );
    }

    final Article leadStory = articles.first;
    final List<Article> remainingStories = articles.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _NewsToolbar(
          layoutMode: _layoutMode,
          onModeChanged: _setLayoutMode,
          isUsingFallbackData: isUsingFallbackData,
        ),
        const SizedBox(height: 18),
        _LeadStoryCard(
          article: leadStory,
          onTap: () => _openArticle(leadStory),
        ),
        if (remainingStories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 22),
          Text(
            'Latest Coverage',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppTheme.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'A multi-source wire built for quick scanning and deeper in-app reading.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _buildStoryCollection(context, remainingStories),
        ],
      ],
    );
  }

  Widget _buildStoryCollection(BuildContext context, List<Article> articles) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool canUseTwoColumns = constraints.maxWidth >= 900;
        final int crossAxisCount = _layoutMode == _NewsLayoutMode.grid
            ? (canUseTwoColumns ? 2 : 1)
            : 1;

        if (_layoutMode == _NewsLayoutMode.list) {
          return Column(
            key: const Key('news-list'),
            children: articles
                .map(
                  (Article article) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _StoryCard(
                      article: article,
                      onTap: () => _openArticle(article),
                      layoutMode: _StoryCardLayout.list,
                    ),
                  ),
                )
                .toList(),
          );
        }

        final double aspectRatio = crossAxisCount == 1
            ? 2.0
            : (constraints.maxWidth > 1040 ? 1.18 : 1.02);

        return GridView.builder(
          key: const Key('news-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (BuildContext context, int index) {
            final Article article = articles[index];
            return _StoryCard(
              article: article,
              onTap: () => _openArticle(article),
              layoutMode: _StoryCardLayout.compact,
            );
          },
        );
      },
    );
  }

  void _setLayoutMode(_NewsLayoutMode layoutMode) {
    if (_layoutMode == layoutMode) {
      return;
    }

    setState(() {
      _layoutMode = layoutMode;
    });
  }

  Future<void> _openArticle(Article article) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            widget.readerPageBuilder?.call(context, article) ??
            ArticleReaderPage(article: article),
      ),
    );
  }
}

class _NewsToolbar extends StatelessWidget {
  const _NewsToolbar({
    required this.layoutMode,
    required this.onModeChanged,
    required this.isUsingFallbackData,
  });

  final _NewsLayoutMode layoutMode;
  final ValueChanged<_NewsLayoutMode> onModeChanged;
  final bool isUsingFallbackData;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SegmentedButton<_NewsLayoutMode>(
          segments: const <ButtonSegment<_NewsLayoutMode>>[
            ButtonSegment<_NewsLayoutMode>(
              value: _NewsLayoutMode.list,
              icon: Icon(Icons.view_agenda_outlined),
              label: Text('List'),
            ),
            ButtonSegment<_NewsLayoutMode>(
              value: _NewsLayoutMode.grid,
              icon: Icon(Icons.grid_view_rounded),
              label: Text('Grid'),
            ),
          ],
          selected: <_NewsLayoutMode>{layoutMode},
          onSelectionChanged: (Set<_NewsLayoutMode> selection) {
            onModeChanged(selection.first);
          },
        ),
        Chip(
          avatar: const Icon(Icons.hub_outlined, size: 18),
          label: Text(isUsingFallbackData ? 'Demo feed' : 'NewsAPI + GNews'),
        ),
      ],
    );
  }
}

class _LeadStoryCard extends StatelessWidget {
  const _LeadStoryCard({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>('news-card-${article.dedupeKey}'),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              _MetaRow(article: article),
              const SizedBox(height: 14),
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.ink,
                  fontSize: 34,
                ),
              ),
              if (article.description.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  article.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _StoryCardLayout { list, compact }

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.article,
    required this.onTap,
    required this.layoutMode,
  });

  final Article article;
  final VoidCallback onTap;
  final _StoryCardLayout layoutMode;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>('news-card-${article.dedupeKey}'),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: layoutMode == _StoryCardLayout.list
            ? _ListStoryCardBody(article: article)
            : _CompactStoryCardBody(article: article),
      ),
    );
  }
}

class _ListStoryCardBody extends StatelessWidget {
  const _ListStoryCardBody({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MetaRow(article: article),
          const SizedBox(height: 10),
          Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.ink,
              fontSize: 28,
            ),
          ),
          if (article.description.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              article.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.76),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactStoryCardBody extends StatelessWidget {
  const _CompactStoryCardBody({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _MetaRow(article: article),
            const SizedBox(height: 10),
            Text(
              article.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.ink,
                fontSize: 24,
              ),
            ),
            if (article.description.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  article.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink.withValues(alpha: 0.76),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Container(
          key: ValueKey<String>('news-meta-source-${article.dedupeKey}'),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            article.source.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTheme.accentRed),
          ),
        ),
        Text(
          DateFormat('MMM d • h:mm a').format(article.publishedAt.toLocal()),
          key: ValueKey<String>('news-meta-timestamp-${article.dedupeKey}'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NewsStateCard extends StatelessWidget {
  const _NewsStateCard({
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 36, color: AppTheme.accentRed),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppTheme.ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.ink.withValues(alpha: 0.82),
              ),
            ),
            if (showProgress) ...<Widget>[
              const SizedBox(height: 18),
              const CircularProgressIndicator(),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 18),
              FilledButton(
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
