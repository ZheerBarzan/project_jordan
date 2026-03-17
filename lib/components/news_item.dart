import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsItem extends StatelessWidget {
  final Article article;
  const NewsItem({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: SizedBox(
          height: 500,
          width: double.infinity,
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    imageErrorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return Icon(Icons.image, color: Colors.grey.shade600);
                        },
                    fit: BoxFit.cover,
                    image:
                        article.urlToImage ?? "https://via.placeholder.com/108",
                  ),
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
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  article.description,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.captionText(),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 30,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final Uri articleUri = Uri.parse(article.url);
                          if (!await launchUrl(articleUri)) {
                            throw Exception('Could not launch $articleUri');
                          }
                        },
                        icon: const Icon(Icons.open_in_new_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text: 'check out this article ${article.url}',
                            ),
                          );
                        },
                        icon: const Icon(Icons.send),
                      ),
                      IconButton(
                        onPressed: () async {
                          await FlutterClipboard.copy(article.url);
                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("copied")),
                          );
                        },
                        icon: const Icon(Icons.copy),
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
