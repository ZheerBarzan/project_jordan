import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/services/news_api_provider.dart';

@Deprecated('Use NewsApiProvider instead.')
class NewsApi extends NewsApiProvider {
  NewsApi({super.client, super.apiKey});

  Future<List<Article>> fetchArticles(String category) {
    return fetchLatestNbaNews();
  }
}
