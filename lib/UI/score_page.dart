import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:project_jordan/components/game_List.dart';
import 'package:project_jordan/model/teams.dart';
import 'package:http/http.dart' as http;

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GameList(),
    );
  }
}
