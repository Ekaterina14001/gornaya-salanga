import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/salanga_colors.dart';

/// Brand PNG/SVG icons from `assets/icons/`.
abstract final class SalangaAssets {
  static const icons = 'assets/icons';
  static const banners = 'assets/banners';

  static const home = '$icons/home.png';
  static const bonus = '$icons/bonus.png';
  static const bonusActive = '$icons/bonus_active.png';
  static const catalog = '$icons/catalog.png';
  static const profile = '$icons/profile.png';
  static const bookRoom = '$icons/book_room.png';
  static const weather = '$icons/weather.png';
  static const trails = '$icons/trails.png';
  static const webcams = '$icons/webcams.png';
  static const contact = '$icons/contact.png';
  static const qr = '$icons/qr.png';
  static const notifications = '$icons/notifications.png';
  static const chevron = '$icons/chevron.png';
  static const branch = '$icons/branch.png';
  static const logo = '$icons/logo_gs.png';

  static const bannerChalet = '$banners/banner_chalet.jpg';
  static const bannerWelcome = '$banners/banner_welcome.jpg';
}

class SalangaAssetIcon extends StatelessWidget {
  const SalangaAssetIcon({
    super.key,
    required this.asset,
    this.size = 26,
    this.color,
    this.tint = true,
    this.semanticsLabel,
  });

  final String asset;
  final double size;
  final Color? color;
  final bool tint;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    if (asset.endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        width: size,
        height: size,
        semanticsLabel: semanticsLabel,
        colorFilter: tint && color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      );
    }
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticsLabel,
    );
    if (!tint || color == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      child: image,
    );
  }
}

/// Trailing chevron for list rows.
class SalangaChevron extends StatelessWidget {
  const SalangaChevron({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SalangaAssetIcon(
      asset: SalangaAssets.chevron,
      size: size,
      color: color ?? SalangaColors.menuIcon,
    );
  }
}
