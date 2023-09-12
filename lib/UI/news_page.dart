import 'package:flutter/material.dart';
import 'package:project_jordan/components/news_list.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: NewsListPage());
  }
}
