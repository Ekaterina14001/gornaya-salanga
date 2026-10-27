import 'package:flutter/material.dart';

import '../../core/network/media_url.dart';
import 'salanga_avatar_logo.dart';

/// Круглая иконка: [imageUrl] пользователя или локальный брендовый знак (прозрачный PNG).
class SalangaNetworkIcon extends StatelessWidget {
  const SalangaNetworkIcon({
    super.key,
    this.size = 40,
    this.imageUrl,
    this.semanticsLabel = 'Горная Саланга',
  });

  final double size;
  final String? imageUrl;
  final String semanticsLabel;

  String? get _resolvedUrl {
    final custom = (imageUrl ?? '').trim();
    if (custom.isEmpty) return null;
    final u = resolveMediaUrl(custom);
    return u.isNotEmpty ? u : null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    if (url == null || url.isEmpty) {
      return SalangaAvatarLogo(size: size, semanticsLabel: semanticsLabel);
    }

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: semanticsLabel,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) =>
            SalangaAvatarLogo(size: size, semanticsLabel: semanticsLabel),
      ),
    );
  }
}
