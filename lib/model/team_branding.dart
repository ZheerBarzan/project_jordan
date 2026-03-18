class TeamBranding {
  const TeamBranding({
    required this.abbreviation,
    this.logoAsset,
    this.primaryColorValue,
    this.secondaryColorValue,
  });

  final String abbreviation;
  final String? logoAsset;
  final int? primaryColorValue;
  final int? secondaryColorValue;

  bool get hasLogoAsset => (logoAsset ?? '').isNotEmpty;

  factory TeamBranding.fromJson(
    String abbreviation,
    Map<String, dynamic> json,
  ) {
    return TeamBranding(
      abbreviation: abbreviation.toUpperCase(),
      logoAsset: (json['logoAsset'] as String?)?.trim(),
      primaryColorValue: _parseColorValue(json['primaryColor']),
      secondaryColorValue: _parseColorValue(json['secondaryColor']),
    );
  }

  static int? _parseColorValue(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is int) {
      return raw;
    }

    final String normalized = raw
        .toString()
        .replaceFirst('#', '')
        .replaceFirst('0x', '')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }

    final String hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    return int.tryParse(hex, radix: 16);
  }
}
