import 'package:project_jordan/model/news_model.dart';

abstract class NewsProvider {
  String get providerName;

  Future<List<Article>> fetchLatestNbaNews();
}

class NewsProviderException implements Exception {
  const NewsProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
