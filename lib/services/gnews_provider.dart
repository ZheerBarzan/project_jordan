import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/services/news_provider.dart';

class GNewsProvider implements NewsProvider {
  GNewsProvider({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? _defaultApiKey;

  static const String _authority = 'gnews.io';
  static const String _defaultApiKey = String.fromEnvironment('GNEWS_API_KEY');

  final http.Client _client;
  final String _apiKey;

  @override
  String get providerName => 'GNews';

  @override
  Future<List<Article>> fetchLatestNbaNews() async {
    if (_apiKey.isEmpty) {
      throw const NewsProviderException(
        'GNEWS_API_KEY is missing. Add it with --dart-define to enable the fallback NBA news feed.',
      );
    }

    final Uri uri = Uri.https(_authority, '/api/v4/search', <String, String>{
      'q': '(NBA OR basketball) AND NOT NCAA',
      'lang': 'en',
      'country': 'us',
      'max': '20',
      'in': 'title,description',
      'sortby': 'publishedAt',
      'nullable': 'description,image',
      'apikey': _apiKey,
    });

    final http.Response response = await _client.get(uri);
    final Map<String, dynamic> json = _decodeJson(response.body);

    if (response.statusCode != 200) {
      throw NewsProviderException(
        (json['errors']?.toString() ??
                json['message'] ??
                'Failed to load GNews articles.')
            .toString(),
      );
    }

    final List<dynamic> articlesJson =
        json['articles'] as List<dynamic>? ?? <dynamic>[];
    return articlesJson
        .map(
          (dynamic article) =>
              Article.fromGNewsJson(article as Map<String, dynamic>),
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
