import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/salanga_colors.dart';
import '../../../../shared/widgets/salanga_asset_icon.dart';
import '../../catalog_sections.dart';

/// Список разделов каталога — тёмно-коричневая панель, отдельные «pill»-кнопки.
class CatalogHubView extends StatelessWidget {
  const CatalogHubView({
    super.key,
    required this.onSectionSelected,
    this.onRefresh,
    this.refreshing = false,
  });

  final ValueChanged<CatalogSection> onSectionSelected;
  final VoidCallback? onRefresh;
  final bool refreshing;

  static const _itemRadius = 22.0;
  static const _itemGap = 10.0;
  static const _groupGap = 18.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: SalangaColors.catalogHubBackground,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 24),
            children: [
              for (var g = 0; g < catalogSectionGroups.length; g++) ...[
                if (g > 0) const SizedBox(height: _groupGap),
                for (final item in catalogSectionGroups[g]) ...[
                  _CatalogHubPill(
                    title: item.label,
                    onTap: () => onSectionSelected(item.section),
                  ),
                  if (item != catalogSectionGroups[g].last)
                    const SizedBox(height: _itemGap),
                ],
              ],
            ],
          ),
          if (onRefresh != null)
            Positioned(
              top: top + 4,
              right: 8,
              child: IconButton(
                tooltip: 'Обновить',
                onPressed: refreshing ? null : onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: SalangaColors.catalogHubText.withValues(alpha: 0.92),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogHubPill extends StatelessWidget {
  const _CatalogHubPill({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SalangaColors.catalogHubItem,
      borderRadius: BorderRadius.circular(CatalogHubView._itemRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: SalangaColors.catalogHubText.withValues(alpha: 0.12),
        highlightColor: SalangaColors.catalogHubText.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textScaler: TextScaler.noScaling,
                  style: GoogleFonts.openSans(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w400,
                    color: SalangaColors.catalogHubText,
                  ),
                ),
              ),
              const SalangaChevron(
                size: 20,
                color: SalangaColors.catalogHubChevron,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
