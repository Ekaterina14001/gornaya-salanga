import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/salanga_colors.dart';
import 'salanga_asset_icon.dart';

/// Нижняя навигация: разделители + прямоугольная подсветка вкладки (как в макете).
class SalangaBottomNavBar extends StatelessWidget {
  const SalangaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SalangaNavBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SalangaColors.navBar,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    color: SalangaColors.border.withValues(alpha: 0.55),
                  ),
                Expanded(
                  child: _SalangaNavTile(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SalangaNavBarItem {
  const SalangaNavBarItem({
    required this.iconAsset,
    required this.activeIconAsset,
    required this.label,
  });

  final String iconAsset;
  final String activeIconAsset;
  final String label;
}

class _SalangaNavTile extends StatefulWidget {
  const _SalangaNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SalangaNavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SalangaNavTile> createState() => _SalangaNavTileState();
}

class _SalangaNavTileState extends State<_SalangaNavTile> {
  bool _pressed = false;

  bool get _highlighted => widget.selected || _pressed;

  @override
  Widget build(BuildContext context) {
    final iconAsset =
        _highlighted ? widget.item.activeIconAsset : widget.item.iconAsset;
    final iconColor = _highlighted
        ? SalangaColors.navBarActive
        : SalangaColors.navBarInactive;
    final labelColor =
        _highlighted ? SalangaColors.navBarActive : SalangaColors.navBarInactive;

    return Material(
      color: _highlighted
          ? SalangaColors.navBarSelected
          : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        splashColor: SalangaColors.warmBrown.withValues(alpha: 0.2),
        highlightColor: SalangaColors.navBarSelected.withValues(alpha: 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SalangaAssetIcon(
              asset: iconAsset,
              size: 28,
              color: iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontWeight: _highlighted ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
