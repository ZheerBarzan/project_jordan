import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_jordan/services/gnews_provider.dart';

void main() {
  test('GNewsProvider parses a successful response', () async {
    final GNewsProvider provider = GNewsProvider(
      apiKey: 'gnews-key',
      client: MockClient((http.Request request) async {
        expect(request.url.host, 'gnews.io');
        expect(request.url.path, '/api/v4/search');
        expect(request.url.queryParameters['apikey'], 'gnews-key');

        return http.Response('''
          {
            "articles": [
              {
                "title": "Latest NBA Trade",
                "description": "Front office update",
                "content": "Trade market full update",
                "url": "https://example.com/gnews-story",
                "publishedAt": "2026-03-17T11:00:00Z",
                "image": "https://example.com/image.png",
                "source": {"name": "CBS Sports"}
              }
            ]
          }
        ''', 200);
      }),
    );

    final articles = await provider.fetchLatestNbaNews();

    expect(articles, hasLength(1));
    expect(articles.first.source, 'CBS Sports');
    expect(articles.first.urlToImage, 'https://example.com/image.png');
    expect(articles.first.content, 'Trade market full update');
  });
}
