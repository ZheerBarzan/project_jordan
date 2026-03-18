import 'package:flutter/foundation.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/repositories/fallback_aware_repository.dart';
import 'package:project_jordan/services/asset_fixture_loader.dart';
import 'package:project_jordan/services/gnews_provider.dart';
import 'package:project_jordan/services/news_api_provider.dart';
import 'package:project_jordan/services/news_provider.dart';

abstract class NewsFeedRepository {
  Future<List<Article>> fetchLatestNbaNews();
}

class NewsRepository implements NewsFeedRepository, FallbackAwareRepository {
  NewsRepository({
    List<NewsProvider>? providers,
    AssetFixtureLoader? fixtureLoader,
  }) : providers =
           providers ?? <NewsProvider>[NewsApiProvider(), GNewsProvider()],
       _fixtureLoader = fixtureLoader ?? AssetFixtureLoader();

  static const String _fallbackAssetPath = 'assets/data/fallback_news.json';

  final List<NewsProvider> providers;
  final AssetFixtureLoader _fixtureLoader;
  final ValueNotifier<bool> _isUsingFallbackData = ValueNotifier<bool>(false);

  @override
  ValueListenable<bool> get isUsingFallbackData => _isUsingFallbackData;

  @override
  Future<List<Article>> fetchLatestNbaNews() async {
    _isUsingFallbackData.value = false;

    if (providers.isEmpty) {
      return _loadFallbackArticles();
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

    final List<Article> fallbackArticles = await _loadFallbackArticles();
    if (fallbackArticles.isNotEmpty) {
      _isUsingFallbackData.value = true;
      return fallbackArticles;
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
      if (existing == null || _shouldReplace(existing, article)) {
        uniqueArticles[key] = article;
      }
    }

    final List<Article> sorted = uniqueArticles.values.toList()
      ..sort((Article a, Article b) => b.publishedAt.compareTo(a.publishedAt));

    return sorted;
  }

  bool _shouldReplace(Article existing, Article candidate) {
    final bool existingHasImage = _hasUsableImage(existing);
    final bool candidateHasImage = _hasUsableImage(candidate);

    if (candidateHasImage != existingHasImage) {
      return candidateHasImage;
    }

    return candidate.publishedAt.isAfter(existing.publishedAt);
  }

  bool _hasUsableImage(Article article) {
    return (article.urlToImage ?? '').trim().isNotEmpty;
  }

  Future<List<Article>> _loadFallbackArticles() async {
    final List<Map<String, dynamic>> fixtures = await _fixtureLoader
        .loadJsonList(_fallbackAssetPath);

    return _normalize(fixtures.map(_articleFromFixture).toList());
  }

  Article _articleFromFixture(Map<String, dynamic> json) {
    final Article article = Article.fromJson(json);
    final int offsetHours =
        (json['fallback_offset_hours'] as num?)?.toInt() ?? 0;
    final DateTime publishedAt = offsetHours > 0
        ? DateTime.now().toUtc().subtract(Duration(hours: offsetHours))
        : article.publishedAt;

    return Article(
      title: article.title,
      description: article.description,
      url: article.url,
      publishedAt: publishedAt,
      source: article.source,
      urlToImage: article.urlToImage,
      author: article.author,
      content: article.content,
    );
  }
}
