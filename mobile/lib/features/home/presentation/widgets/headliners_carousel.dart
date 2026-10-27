import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/media_url.dart';
import '../../../../core/theme/salanga_colors.dart';
import '../../../../shared/widgets/home_banner_constants.dart';
import '../../../../shared/widgets/admin_banner_image.dart';
import '../../../../shared/widgets/home_banner_defaults.dart';

/// Нижние баннеры: свайп, виден следующий слайд, cover в плитке (как макет).
class HeadlinersCarousel extends StatelessWidget {
  const HeadlinersCarousel({required this.bottomBanners, super.key});

  final List<Map<String, dynamic>> bottomBanners;

  Future<void> _openLink(BuildContext context, String? link) async {
    if (link == null || link.isEmpty) return;
    if (link.startsWith('http://') || link.startsWith('https://')) {
      final uri = Uri.tryParse(link);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    if (link.startsWith('/')) {
      if (context.mounted) context.go(link);
    }
  }

  String? _imageUrl(Map<String, dynamic> item) {
    final sort = HomeBannerDefaults.sortOrderFromJson(item['sortOrder'], fallback: 1);
    final raw = item['imageUrl']?.toString();
    final resolved = resolveBannerMediaUrl(HomeBannerDefaults.effective(raw, sort));
    return resolved.isNotEmpty ? resolved : null;
  }

  @override
  Widget build(BuildContext context) {
    if (bottomBanners.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final multi = bottomBanners.length > 1;
        final viewportFraction = multi
            ? kHomeCarouselViewportFraction(maxW)
            : 1.0;
        final tileHeight = kHomeCarouselTileHeight(maxW);

        return SizedBox(
          height: tileHeight,
          width: maxW,
          child: PageView.builder(
            controller: PageController(viewportFraction: viewportFraction),
            padEnds: false,
            clipBehavior: Clip.none,
            itemCount: bottomBanners.length,
            itemBuilder: (context, index) {
              final item = bottomBanners[index];
              final url = _imageUrl(item);
              final link = item['linkUrl']?.toString();
              final sort = HomeBannerDefaults.sortOrderFromJson(item['sortOrder'], fallback: 1);

              return Padding(
                padding: EdgeInsets.only(
                  right: index < bottomBanners.length - 1 ? kHomeBannerGap : 0,
                ),
                child: _AdminBannerTile(
                  imageUrl: url,
                  sortOrder: sort,
                  onTap: link != null && link.isNotEmpty
                      ? () => _openLink(context, link)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AdminBannerTile extends StatelessWidget {
  const _AdminBannerTile({
    required this.imageUrl,
    required this.sortOrder,
    this.onTap,
  });

  final String? imageUrl;
  final int sortOrder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kHomeBannerRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kHomeBannerRadius),
          child: ColoredBox(
            color: SalangaColors.textDark,
            child: AdminBannerImage(imageUrl: imageUrl, sortOrder: sortOrder),
          ),
        ),
      ),
    );
  }
}
