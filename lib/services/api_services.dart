import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_jordan/model/news_model.dart';

class NewsApi {
  NewsApi({http.Client? client}) : _client = client ?? http.Client();

  static const String _authority = 'newsapi.org';
  static const String _apiKey = 'c212bebdac9741d3870383d4ca2d4e1f';

  final http.Client _client;

  Future<List<Article>> fetchArticles(String category) async {
    final Uri uri = Uri.https(_authority, '/v2/top-headlines', <String, String>{
      'apiKey': _apiKey,
      'language': 'en',
      'category': 'sports',
      'q': category,
    });
    final http.Response response = await _client.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] == "ok") {
        final List<dynamic> articleJson =
            json['articles'] as List<dynamic>? ?? <dynamic>[];
        final List<Article> articles = articleJson
            .map(
              (dynamic article) =>
                  Article.fromJson(article as Map<String, dynamic>),
            )
            .toList();
        return articles;
      }

      throw Exception(json['message'] ?? 'Failed to load news.');
    }

    throw Exception('Bad response from News API.');
  }
}
