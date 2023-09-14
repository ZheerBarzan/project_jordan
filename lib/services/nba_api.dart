import 'dart:convert';

import 'package:project_jordan/model/game_model.dart';
import 'package:http/http.dart' as http;

class NbaAPI {
  const NbaAPI();

  static const baseUrl = "https://www.balldontlie.io/api/v1/games/";

  Future<List<Game>> fetchArticles(String catagory) async {
    var url = NbaAPI.baseUrl;

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == "ok") {
        final dynamic articleJSON = json['articles'] ?? [];
        final List<Game> articles = articleJSON.map<Game>((e) {
          return Game.fromJson(e);
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
