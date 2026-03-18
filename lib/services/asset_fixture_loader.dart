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

  Future<Map<String, Map<String, dynamic>>> loadJsonObjectMap(
    String assetPath,
  ) async {
    final String raw = await _loadString(assetPath);
    final dynamic decoded = jsonDecode(raw);

    if (decoded is! Map<dynamic, dynamic>) {
      throw const FormatException(
        'Fixture file must contain a top-level object.',
      );
    }

    return decoded.map(
      (dynamic key, dynamic value) => MapEntry<String, Map<String, dynamic>>(
        key.toString(),
        Map<String, dynamic>.from(value as Map<dynamic, dynamic>),
      ),
    );
  }
}
