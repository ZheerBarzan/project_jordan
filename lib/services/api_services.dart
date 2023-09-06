import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String apiKey = 'c212bebdac9741d3870383d4ca2d4e1f';
  final String newsApiEndpoint = 'https://newsapi.org/v2/everything';

  Future<List<Map<String, dynamic>>> fetchNbaNews() async {
    final Map<String, String> queryParams = {
      'q': 'NBA',
      'apiKey': apiKey,
    };

    final Uri uri =
        Uri.parse(newsApiEndpoint).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('articles')) {
        return List<Map<String, dynamic>>.from(responseData['articles']);
      }
    }

    return [];
  }
}
