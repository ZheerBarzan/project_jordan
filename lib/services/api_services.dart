import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project_jordan/model/news_model.dart';

class NewsApi {
  const NewsApi();

  static const baseUrl = "https://newsapi.org/v2";
  static const apiKey = "c212bebdac9741d3870383d4ca2d4e1f";

  Future<List<Article>> fetchArticles(String catagory) async {
    var url = NewsApi.baseUrl;

    url += '/top-headlines';
    url += '?apiKey=$apiKey';
    url += "&language=en";
    url += "&category=Sports";
    url += "&q=$catagory";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == "ok") {
        final dynamic articleJSON = json['articles'] ?? [];
        final List<Article> articles = articleJSON.map<Article>((e) {
          return Article.fromJson(e);
        }).toList();
        return articles;
      } else {
        throw Exception(json['messege'] ?? 'Failed to load ');
      }
    } else {
      throw Exception("bad respose");
    }
  }
}
