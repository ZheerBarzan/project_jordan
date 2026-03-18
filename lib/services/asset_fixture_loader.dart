import 'dart:convert';

import 'package:flutter/services.dart';

class AssetFixtureLoader {
  AssetFixtureLoader({Future<String> Function(String path)? loadString})
    : _loadString = loadString ?? rootBundle.loadString;

  final Future<String> Function(String path) _loadString;

  Future<List<Map<String, dynamic>>> loadJsonList(String assetPath) async {
    final String raw = await _loadString(assetPath);
    final dynamic decoded = jsonDecode(raw);

    if (decoded is! List<dynamic>) {
      throw const FormatException(
        'Fixture file must contain a top-level list.',
      );
    }

    return decoded
        .map(
          (dynamic entry) =>
              Map<String, dynamic>.from(entry as Map<dynamic, dynamic>),
        )
        .toList();
  }
}
