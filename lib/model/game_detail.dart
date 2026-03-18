import 'package:project_jordan/model/game_model.dart';

class GameDetail {
  const GameDetail({
    required this.game,
    this.arena,
    this.location,
    this.headline,
    this.summary,
    this.notes = const <String>[],
    this.homeLineScores = const <int>[],
    this.visitorLineScores = const <int>[],
  });

  final Game game;
  final String? arena;
  final String? location;
  final String? headline;
  final String? summary;
  final List<String> notes;
  final List<int> homeLineScores;
  final List<int> visitorLineScores;

  bool get hasSummary => (summary ?? '').trim().isNotEmpty;

  bool get hasVenue => (arena ?? '').trim().isNotEmpty;

  bool get hasLocation => (location ?? '').trim().isNotEmpty;

  bool get hasNotes => notes.isNotEmpty;

  bool get hasLineScore =>
      homeLineScores.isNotEmpty &&
      visitorLineScores.isNotEmpty &&
      (!game.isScheduled ||
          homeLineScores.any((int score) => score > 0) ||
          visitorLineScores.any((int score) => score > 0));

  bool get hasEnrichment =>
      hasVenue || hasLocation || hasSummary || hasNotes || hasLineScore;

  factory GameDetail.fromGame(
    Game game, {
    Map<String, dynamic>? enrichment,
  }) {
    final Map<String, dynamic> json = enrichment ?? const <String, dynamic>{};

    return GameDetail(
      game: game,
      arena: (json['arena'] as String?)?.trim(),
      location: (json['location'] as String?)?.trim(),
      headline: (json['headline'] as String?)?.trim(),
      summary: (json['summary'] as String?)?.trim(),
      notes: (json['notes'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic entry) => entry.toString().trim())
          .where((String entry) => entry.isNotEmpty)
          .toList(),
      homeLineScores: (json['homeLineScores'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic entry) => (entry as num).toInt())
          .toList(),
      visitorLineScores:
          (json['visitorLineScores'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic entry) => (entry as num).toInt())
              .toList(),
    );
  }
}
