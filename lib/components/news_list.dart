import 'package:flutter/material.dart';
import 'package:project_jordan/components/news_item.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/services/api_services.dart';

class NewsListPage extends StatefulWidget {
  final NewsApi newsApi = const NewsApi();
  const NewsListPage({
    super.key,
  });

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  late Future<List<Article>> futureArticles;

  @override
  void initState() {
    super.initState();
    futureArticles = widget.newsApi.fetchArticles("nba");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Article>>(
        future: futureArticles,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemBuilder: (context, index) {
                    return NewsItem(
                      article: snapshot.data![index],
                    );
                  },
                )
              : const Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(),
                  ),
                );
        },
      ),
    );
  }
}
