import 'package:flutter/material.dart';
import 'package:project_jordan/model/team_branding.dart';
import 'package:project_jordan/theme/app_theme.dart';

class TeamLogoBadge extends StatelessWidget {
  const TeamLogoBadge({
    super.key,
    required this.abbreviation,
    required this.teamName,
    this.branding,
    this.size = 56,
    this.borderRadius,
  });

  final String abbreviation;
  final String teamName;
  final TeamBranding? branding;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? size * 0.32;
    final Color tint = _brandColor.withValues(alpha: 0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _brandColor.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: branding?.hasLogoAsset ?? false
          ? Image.asset(
              branding!.logoAsset!,
              fit: BoxFit.contain,
              errorBuilder:
                  (BuildContext _, Object error, StackTrace? stackTrace) =>
                      _FallbackMonogram(
                        abbreviation: abbreviation,
                        color: _brandColor,
                      ),
            )
          : _FallbackMonogram(abbreviation: abbreviation, color: _brandColor),
    );
  }

  Color get _brandColor {
    final int? colorValue = branding?.primaryColorValue;
    if (colorValue != null) {
      return Color(colorValue);
    }
    return AppTheme.nbaBlue;
  }
}

class _FallbackMonogram extends StatelessWidget {
  const _FallbackMonogram({required this.abbreviation, required this.color});

  final String abbreviation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        abbreviation,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: color, fontSize: 18),
      ),
    );
  }
}
