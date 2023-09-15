import 'dart:convert';

import 'package:project_jordan/model/game_model.dart';
import 'package:http/http.dart' as http;

class NbaAPI {
  const NbaAPI();

  static const baseUrl = "https://www.balldontlie.io/api/v1/games";

  Future<List<Game>> fetchGames(int year) async {
    var url = NbaAPI.baseUrl;
    url += "?seasons[]=${year.toString()}";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final dynamic articleJSON = json['data'] ?? [];
      final List<Game> articles = articleJSON.map<Game>((e) {
        return Game.fromJson(e);
      }).toList();
      return articles;
    } else {
      throw Exception('Failed to load ');
    }
  }
}
