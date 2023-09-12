import 'package:flutter/material.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:transparent_image/transparent_image.dart';

class NewsItem extends StatelessWidget {
  final Article article;
  const NewsItem({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return Card();
  }
}



/*
Card(
      child: Container(
        height: 600,
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5), topRight: Radius.circular(5)),
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey.shade300,
                child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image,
                        color: Colors.grey.shade600,
                      );
                    },
                    fit: BoxFit.cover,
                    image: article.urlToImage ??
                        "https://via.placeholder.com/108"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 8,
                right: 8,
              ),
              child: Text(
                article.title,
                style: const TextStyle(fontSize: 20),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.captionText(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
 */