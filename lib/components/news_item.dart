import 'package:flutter/material.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsItem extends StatelessWidget {
  final Article article;
  const NewsItem({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Container(
          height: 500,
          width: double.infinity,
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: Container(
                  height: 250,
                  width: double.infinity,
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
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: Text(
                  article.title,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 30,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 8, left: 8, right: 8, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.captionText(),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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