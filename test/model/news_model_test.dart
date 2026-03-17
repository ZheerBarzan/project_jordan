import 'package:flutter_test/flutter_test.dart';
import 'package:project_jordan/model/news_model.dart';

void main() {
  test('Article.fromJson maps news payload fields', () {
    final Article article = Article.fromJson(<String, dynamic>{
      'title': 'Playoffs update',
      'description': 'The latest playoff update.',
      'url': 'https://example.com/story',
      'publishedAt': '2026-03-17T10:00:00Z',
      'source': <String, dynamic>{'name': 'ESPN'},
      'urlToImage': 'https://example.com/image.png',
    });

    expect(article.title, 'Playoffs update');
    expect(article.description, 'The latest playoff update.');
    expect(article.url, 'https://example.com/story');
    expect(article.source, 'ESPN');
    expect(article.urlToImage, 'https://example.com/image.png');
    expect(article.captionText(), contains('ESPN'));
  });
}
