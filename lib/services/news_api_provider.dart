import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/services/news_provider.dart';

class NewsApiProvider implements NewsProvider {
  NewsApiProvider({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? _defaultApiKey;

  static const String _authority = 'newsapi.org';
  static const String _defaultApiKey = String.fromEnvironment(
    'NEWSAPI_API_KEY',
  );

  final http.Client _client;
  final String _apiKey;

  @override
  String get providerName => 'NewsAPI';

  @override
  Future<List<Article>> fetchLatestNbaNews() async {
    if (_apiKey.isEmpty) {
      throw const NewsProviderException(
        'NEWSAPI_API_KEY is missing. Add it with --dart-define to enable the primary NBA news feed.',
      );
    }

    final Uri uri = Uri.https(_authority, '/v2/top-headlines', <String, String>{
      'apiKey': _apiKey,
      'language': 'en',
      'country': 'us',
      'category': 'sports',
      'q': 'NBA',
      'pageSize': '20',
    });

    final http.Response response = await _client.get(uri);
    final Map<String, dynamic> json = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw NewsProviderException(
        (json['message'] ?? 'Failed to load NewsAPI articles.').toString(),
      );
    }

    if ((json['status'] ?? '').toString() != 'ok') {
      throw NewsProviderException(
        (json['message'] ?? 'NewsAPI returned an invalid response.').toString(),
      );
    }

    final List<dynamic> articlesJson =
        json['articles'] as List<dynamic>? ?? <dynamic>[];
    return articlesJson
        .map(
          (dynamic article) =>
              Article.fromJson(article as Map<String, dynamic>),
        )
        .where((Article article) => article.hasEssentialContent)
        .toList();
  }

  Map<String, dynamic> _decodeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{'message': body};
    }
  }
}
