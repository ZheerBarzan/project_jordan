import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/repositories/news_repository.dart';
import 'package:project_jordan/services/news_provider.dart';

void main() {
  test('NewsRepository falls back, dedupes, and sorts newest-first', () async {
    final NewsRepository repository = NewsRepository(
      providers: <NewsProvider>[
        _FakeProvider(
          name: 'Primary',
          loader: () async => throw const NewsProviderException('Primary down'),
        ),
        _FakeProvider(
          name: 'Fallback',
          loader: () async => <Article>[
            Article(
              title: 'Story',
              description: 'Fallback older copy',
              url: 'https://example.com/story',
              publishedAt: DateTime.parse('2026-03-17T09:00:00Z'),
              source: 'ESPN',
              urlToImage: null,
            ),
            Article(
              title: 'Second story',
              description: 'Another story',
              url: 'https://example.com/second',
              publishedAt: DateTime.parse('2026-03-17T12:00:00Z'),
              source: 'The Athletic',
              urlToImage: null,
            ),
          ],
        ),
        _FakeProvider(
          name: 'Supplemental',
          loader: () async => <Article>[
            Article(
              title: 'Story',
              description: 'Newer duplicate',
              url: 'https://example.com/story',
              publishedAt: DateTime.parse('2026-03-17T10:00:00Z'),
              source: 'Yahoo Sports',
              urlToImage: null,
            ),
          ],
        ),
      ],
    );

    final List<Article> articles = await repository.fetchLatestNbaNews();

    expect(articles, hasLength(2));
    expect(articles.first.title, 'Second story');
    expect(articles.last.source, 'Yahoo Sports');
  });
}

class _FakeProvider implements NewsProvider {
  _FakeProvider({required this.name, required this.loader});

  final String name;
  final Future<List<Article>> Function() loader;

  @override
  String get providerName => name;

  @override
  Future<List<Article>> fetchLatestNbaNews() => loader();
}
