import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/services/gnews_provider.dart';
import 'package:project_jordan/services/news_api_provider.dart';
import 'package:project_jordan/services/news_provider.dart';

abstract class NewsFeedRepository {
  Future<List<Article>> fetchLatestNbaNews();
}

class NewsRepository implements NewsFeedRepository {
  NewsRepository({List<NewsProvider>? providers})
      : providers = providers ??
            <NewsProvider>[
              NewsApiProvider(),
              GNewsProvider(),
            ];

  final List<NewsProvider> providers;

  @override
  Future<List<Article>> fetchLatestNbaNews() async {
    if (providers.isEmpty) {
      return <Article>[];
    }

    final List<String> errors = <String>[];
    final List<Article> collected = <Article>[];

    List<Article> primaryArticles = <Article>[];
    try {
      primaryArticles = await providers.first.fetchLatestNbaNews();
      collected.addAll(primaryArticles);
    } catch (error) {
      errors.add('${providers.first.providerName}: $error');
    }

    if (primaryArticles.isNotEmpty) {
      for (final NewsProvider provider in providers.skip(1)) {
        try {
          collected.addAll(await provider.fetchLatestNbaNews());
        } catch (_) {
          // The primary feed is already available, so optional fallbacks do not
          // need to fail the screen.
        }
      }
    } else {
      for (final NewsProvider provider in providers.skip(1)) {
        try {
          final List<Article> articles = await provider.fetchLatestNbaNews();
          if (articles.isNotEmpty) {
            collected.addAll(articles);
          }
        } catch (error) {
          errors.add('${provider.providerName}: $error');
        }
      }
    }

    final List<Article> normalized = _normalize(collected);
    if (normalized.isNotEmpty) {
      return normalized;
    }

    if (errors.isNotEmpty) {
      throw NewsProviderException(errors.join('\n'));
    }

    throw const NewsProviderException('No NBA news is available right now.');
  }

  List<Article> _normalize(List<Article> articles) {
    final Map<String, Article> uniqueArticles = <String, Article>{};

    for (final Article article in articles) {
      if (!article.hasEssentialContent) {
        continue;
      }

      final String key = article.dedupeKey;
      final Article? existing = uniqueArticles[key];
      if (existing == null || article.publishedAt.isAfter(existing.publishedAt)) {
        uniqueArticles[key] = article;
      }
    }

    final List<Article> sorted = uniqueArticles.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));

    return sorted;
  }
}
