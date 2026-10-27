import 'package:flutter/material.dart';

import 'salanga_asset_icon.dart';

/// Круглый фирменный знак (шляпа / курорт) — единый во всём приложении.
class SalangaAvatarLogo extends StatelessWidget {
  const SalangaAvatarLogo({
    super.key,
    this.size = 40,
    this.semanticsLabel = 'Горная Саланга',
  });

  final double size;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      SalangaAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: semanticsLabel,
      gaplessPlayback: true,
    );
  }
}
