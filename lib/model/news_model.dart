import 'package:timeago/timeago.dart' as timeago;

class Article {
  final String title;
  final String description;
  final String url;
  final DateTime publishedAt;
  final String source;
  final String? urlToImage;

  const Article({
    required this.title,
    required this.description,
    required this.url,
    required this.publishedAt,
    required this.source,
    required this.urlToImage,
  });

  String captionText() {
    final formattedPublishedAt = timeago.format(publishedAt, locale: "en");

    return "$source $formattedPublishedAt";
  }

  bool get hasEssentialContent =>
      title.trim().isNotEmpty &&
      url.trim().isNotEmpty &&
      source.trim().isNotEmpty;

  String get dedupeKey {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      final String path = uri.path.replaceAll(RegExp(r'/$'), '');
      return '${uri.host.toLowerCase()}$path';
    }

    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: (json['title'] ?? "").toString(),
      description: (json['description'] ?? "").toString(),
      url: (json['url'] ?? "").toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']) ?? DateTime.now(),
      source: (json['source']?['name'] ?? "").toString(),
      urlToImage: json['urlToImage'],
    );
  }

  factory Article.fromGNewsJson(Map<String, dynamic> json) {
    return Article(
      title: (json['title'] ?? "").toString(),
      description: (json['description'] ?? "").toString(),
      url: (json['url'] ?? "").toString(),
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ??
          DateTime.now(),
      source: (json['source']?['name'] ?? "").toString(),
      urlToImage: json['image']?.toString(),
    );
  }
}
