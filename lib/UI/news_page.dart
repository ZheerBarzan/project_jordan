import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/repositories/news_repository.dart';
import 'package:project_jordan/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsPage extends StatefulWidget {
  NewsPage({super.key, NewsFeedRepository? repository})
      : repository = repository ?? NewsRepository();

  final NewsFeedRepository repository;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<Article>> _futureArticles;

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
        return RefreshIndicator(
          color: AppTheme.accentRed,
          onRefresh: _reload,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: _buildBody(context, snapshot, constraints.maxWidth),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Article>> snapshot,
    double maxWidth,
  ) {
    final double contentWidth = maxWidth > 1120 ? 1120 : maxWidth;

    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _TabHeader(
            title: 'Latest NBA News',
            subtitle:
                'Featured stories, fresh headlines, and a multi-source feed built for quick scanning.',
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 14),
                Text(
                  'Loading the latest headlines...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (snapshot.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _TabHeader(
            title: 'Latest NBA News',
            subtitle:
                'Featured stories, fresh headlines, and a multi-source feed built for quick scanning.',
          ),
          const SizedBox(height: 22),
          _FeedbackCard(
            icon: Icons.error_outline,
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
          const _TabHeader(
            title: 'Latest NBA News',
            subtitle:
                'Featured stories, fresh headlines, and a multi-source feed built for quick scanning.',
          ),
          const SizedBox(height: 22),
          _FeedbackCard(
            icon: Icons.newspaper_outlined,
            title: 'No stories right now',
            message:
                'The feed came back empty. Pull to refresh or try again in a moment.',
            actionLabel: 'Refresh',
            onAction: _reload,
          ),
        ],
      );
    }

    final Article featuredArticle = articles.first;
    final List<Article> latestArticles = articles.skip(1).take(4).toList();
    final List<Article> remainingArticles = articles.skip(1 + latestArticles.length).toList();
    final bool useTwoColumns = contentWidth > 840;
    final double cardWidth = useTwoColumns ? (contentWidth - 16) / 2 : contentWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _TabHeader(
          title: 'Latest NBA News',
          subtitle:
              'Featured stories, fresh headlines, and a multi-source feed built for quick scanning.',
        ),
        const SizedBox(height: 18),
        _FeaturedArticleCard(
          article: featuredArticle,
          onOpen: () => _openArticle(context, featuredArticle),
          onShare: () => _shareArticle(featuredArticle),
          onCopy: () => _copyLink(context, featuredArticle),
        ),
        if (latestArticles.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'Latest',
            subtitle: 'Quick-hitter headlines from the same live feed.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: latestArticles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                final Article article = latestArticles[index];
                return SizedBox(
                  width: 280,
                  child: _HeadlineStripCard(
                    article: article,
                    onTap: () => _openArticle(context, article),
                  ),
                );
              },
            ),
          ),
        ],
        if (remainingArticles.isNotEmpty) ...<Widget>[
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'More Stories',
            subtitle: 'Everyday coverage, analysis, and injury updates.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: remainingArticles
                .map(
                  (Article article) => SizedBox(
                    width: useTwoColumns ? cardWidth : double.infinity,
                    child: _ArticleCard(
                      article: article,
                      onOpen: () => _openArticle(context, article),
                      onShare: () => _shareArticle(article),
                      onCopy: () => _copyLink(context, article),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _openArticle(BuildContext context, Article article) async {
    final Uri? articleUri = Uri.tryParse(article.url);
    if (articleUri == null) {
      return;
    }

    if (!await launchUrl(articleUri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the article link.')),
      );
    }
  }

  void _shareArticle(Article article) {
    SharePlus.instance.share(
      ShareParams(text: '${article.title}\n${article.url}'),
    );
  }

  Future<void> _copyLink(BuildContext context, Article article) async {
    await FlutterClipboard.copy(article.url);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article link copied')),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
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
              title,
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  const _FeaturedArticleCard({
    required this.article,
    required this.onOpen,
    required this.onShare,
    required this.onCopy,
  });

  final Article article;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 280,
              width: double.infinity,
              child: _ArticleImage(imageUrl: article.urlToImage),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _MetaRow(article: article, isFeatured: true),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 40,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _ActionRow(
                    onOpen: onOpen,
                    onShare: onShare,
                    onCopy: onCopy,
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

class _HeadlineStripCard extends StatelessWidget {
  const _HeadlineStripCard({required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  article.source.toUpperCase(),
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                article.captionText(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.onOpen,
    required this.onShare,
    required this.onCopy,
  });

  final Article article;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 210,
              width: double.infinity,
              child: _ArticleImage(imageUrl: article.urlToImage),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _MetaRow(article: article),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _ActionRow(
                    onOpen: onOpen,
                    onShare: onShare,
                    onCopy: onCopy,
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

class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String image = imageUrl ?? '';
    if (image.isEmpty) {
      return _FallbackArticleImage();
    }

    return FadeInImage.memoryNetwork(
      placeholder: kTransparentImage,
      image: image,
      fit: BoxFit.cover,
      imageErrorBuilder: (_, _, _) => _FallbackArticleImage(),
    );
  }
}

class _FallbackArticleImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.courtBlue,
            AppTheme.nbaBlue,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.article, this.isFeatured = false});

  final Article article;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            article.source.toUpperCase(),
            style: GoogleFonts.oswald(
              color: AppTheme.accentRed,
              fontWeight: FontWeight.w700,
              fontSize: isFeatured ? 15 : 13,
            ),
          ),
        ),
        Text(
          DateFormat('EEE, MMM d • h:mm a').format(article.publishedAt.toLocal()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onOpen,
    required this.onShare,
    required this.onCopy,
  });

  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Open'),
        ),
        TextButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Share'),
        ),
        TextButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy Link'),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppTheme.accentRed, size: 32),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onAction();
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
