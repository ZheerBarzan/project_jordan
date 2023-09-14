import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:project_jordan/model/game_model.dart';
import 'package:project_jordan/model/news_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GameItem extends StatelessWidget {
  final Game game;
  const GameItem({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text("${game.homeTeam} VS ${game.visitorTeam}"),
    );
  }
}
    
    /*Padding(
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
                      image: game. ??
                          "https://via.placeholder.com/108"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                child: Text(
                  game.title,
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
                child: Container(
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 8, left: 8, right: 8, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.captionText(),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 30,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (!await launchUrlString(article.url)) {
                            log('couldnt lunch the URL${article.url}' as num);
                          }
                        },
                        icon: const Icon(Icons.open_in_new_outlined),
                      ),
                      IconButton(
                        onPressed: () {
                          Share.share("check out this article ${article.url}");
                        },
                        icon: const Icon(Icons.send),
                      ),
                      IconButton(
                        onPressed: () {
                          FlutterClipboard.copy(article.url)
                              .then((value) => SnackBar(
                                    content: const Text("copied"),
                                  ));
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
  }*/

