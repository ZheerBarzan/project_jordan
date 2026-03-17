import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_jordan/services/api_services.dart';

void main() {
  test('NewsApi.fetchArticles parses a successful response', () async {
    final NewsApi api = NewsApi(
      client: MockClient((http.Request request) async {
        expect(request.url.host, 'newsapi.org');
        expect(request.url.path, '/v2/top-headlines');

        return http.Response('''
          {
            "status": "ok",
            "articles": [
              {
                "title": "Headline",
                "description": "Story summary",
                "url": "https://example.com/story",
                "publishedAt": "2026-03-17T10:00:00Z",
                "source": {"name": "ESPN"},
                "urlToImage": "https://example.com/image.png"
              }
            ]
          }
        ''', 200);
      }),
    );

    final articles = await api.fetchArticles('nba');

    expect(articles, hasLength(1));
    expect(articles.first.title, 'Headline');
    expect(articles.first.source, 'ESPN');
  });

  test('NewsApi.fetchArticles throws on a bad response', () async {
    final NewsApi api = NewsApi(
      client: MockClient((http.Request request) async {
        return http.Response('Server error', 500);
      }),
    );

    expect(() => api.fetchArticles('nba'), throwsA(isA<Exception>()));
  });
}
