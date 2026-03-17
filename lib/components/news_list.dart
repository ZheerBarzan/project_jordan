import 'package:flutter/material.dart';
import 'package:project_jordan/components/news_item.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:project_jordan/services/api_services.dart';

class NewsListPage extends StatefulWidget {
  final NewsApi? newsApi;
  const NewsListPage({super.key, this.newsApi});

  @override
  State<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  late Future<List<Article>> futureArticles;

  @override
  void initState() {
    super.initState();
    futureArticles = (widget.newsApi ?? NewsApi()).fetchArticles("nba");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Article>>(
        future: futureArticles,
        builder: (BuildContext context, AsyncSnapshot<List<Article>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            final List<Article> articles = snapshot.data!;
            return ListView.builder(
              itemCount: articles.length,
              itemBuilder: (BuildContext context, int index) {
                return NewsItem(article: articles[index]);
              },
            );
          }

          return const Center(
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
