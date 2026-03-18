import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/theme/app_theme.dart';
import 'package:transparent_image/transparent_image.dart';

class ArticleReaderPage extends StatelessWidget {
  const ArticleReaderPage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasContent = (article.content ?? '').trim().isNotEmpty;
    final bool hasDescription = article.description.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.softBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.softBackground,
        foregroundColor: AppTheme.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(article.source, style: theme.textTheme.headlineMedium),
      ),
      body: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _ArticleImage(imageUrl: article.urlToImage),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            article.source.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.accentRed,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, MMM d • h:mm a',
                          ).format(article.publishedAt.toLocal()),
                          style: theme.textTheme.bodySmall,
                        ),
                        if ((article.author ?? '').trim().isNotEmpty)
                          Text(
                            'By ${article.author!.trim()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.nbaBlue,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      article.title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppTheme.ink,
                        fontSize: 42,
                      ),
                    ),
                    if (hasDescription) ...<Widget>[
                      const SizedBox(height: 14),
                      SelectableText(
                        article.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.ink.withValues(alpha: 0.84),
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Article',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (hasContent)
                      SelectableText(
                        article.content!.trim(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.ink,
                          height: 1.7,
                        ),
                      )
                    else if (hasDescription)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SelectableText(
                            article.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.ink,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoNote(
                            message:
                                'Full article text is not available from this news feed payload.',
                          ),
                        ],
                      )
                    else
                      const _InfoNote(
                        message:
                            'Full article text is not available from this news feed payload.',
                      ),
                  ],
                ),
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
    final String image = imageUrl?.trim() ?? '';
    if (image.isEmpty) {
      return const _ArticleFallbackImage();
    }

    return FadeInImage.memoryNetwork(
      placeholder: kTransparentImage,
      image: image,
      fit: BoxFit.cover,
      imageErrorBuilder: (_, _, _) => const _ArticleFallbackImage(),
    );
  }
}

class _ArticleFallbackImage extends StatelessWidget {
  const _ArticleFallbackImage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('article-fallback-image'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppTheme.courtBlue, AppTheme.nbaBlue],
        ),
      ),
      child: Center(
        child: Image.asset(
          'images/nba.png',
          key: const Key('article-fallback-image-asset'),
          width: 132,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('article-content-note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.nbaBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.nbaBlue.withValues(alpha: 0.16)),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
