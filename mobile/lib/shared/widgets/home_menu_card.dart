import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/salanga_colors.dart';
import 'salanga_asset_icon.dart';

/// Макет: Open Sans Regular **30 pt** (середина на comparison-макете).
const kHomeMenuTitleStyle = TextStyle(
  fontSize: 30,
  height: 1.1,
  fontWeight: FontWeight.w400,
  color: SalangaColors.menuText,
);

/// Grouped list rows (weather, trails, webcams) as on the home mockup.
class HomeMenuCard extends StatelessWidget {
  const HomeMenuCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SalangaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SalangaColors.sand),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: SalangaColors.menuDivider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class HomeMenuTile extends StatelessWidget {
  const HomeMenuTile({
    super.key,
    this.iconAsset,
    this.icon,
    required this.title,
    required this.onTap,
    this.badgeCount = 0,
    this.tintIcon = true,
  }) : assert(iconAsset != null || icon != null);

  final String? iconAsset;
  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final int badgeCount;
  final bool tintIcon;

  @override
  Widget build(BuildContext context) {
    final hasUnread = badgeCount > 0;
    final titleStyle = GoogleFonts.openSans(
      fontSize: kHomeMenuTitleStyle.fontSize,
      height: kHomeMenuTitleStyle.height,
      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
      color: SalangaColors.menuText,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      minVerticalPadding: 0,
      leading: iconAsset != null
          ? SalangaAssetIcon(
              asset: iconAsset!,
              size: 30,
              color: SalangaColors.menuIcon,
              tint: tintIcon,
            )
          : Icon(
              icon,
              color: SalangaColors.menuIcon,
              size: 30,
            ),
      title: Text(
        title,
        style: titleStyle,
        textScaler: TextScaler.noScaling,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasUnread)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: SalangaColors.burgundy,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          const SalangaChevron(size: 22, color: SalangaColors.menuIcon),
        ],
      ),
      onTap: onTap,
    );
  }
}
