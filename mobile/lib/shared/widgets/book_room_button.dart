import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/navigation/app_link.dart';
import '../../core/network/media_url.dart';
import '../../core/theme/salanga_colors.dart';
import 'home_banner_constants.dart';
import '../../l10n/app_localizations.dart';
import 'admin_banner_image.dart';
import 'salanga_asset_icon.dart';

const kSalangaBookingUrl = 'https://www.salanga.ru/book/';

class BookRoomButton extends StatelessWidget {
  const BookRoomButton({
    super.key,
    this.compact = false,
    this.fullWidth = true,
    this.promoBar = false,
  });

  final bool compact;
  final bool fullWidth;
  /// Полная ширина баннера, без скругления сверху (нижняя полоса на картинке).
  final bool promoBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final child = _BookRoomButtonContent(
      label: l10n.bookRoom,
      compact: compact,
      promoBar: promoBar,
      onPressed: () => openAppLink(context, kSalangaBookingUrl),
    );

    if (!fullWidth) return child;

    return SizedBox(width: double.infinity, child: child);
  }
}

class _BookRoomButtonContent extends StatefulWidget {
  const _BookRoomButtonContent({
    required this.label,
    required this.compact,
    required this.promoBar,
    required this.onPressed,
  });

  final String label;
  final bool compact;
  final bool promoBar;
  final VoidCallback onPressed;

  @override
  State<_BookRoomButtonContent> createState() => _BookRoomButtonContentState();
}

class _BookRoomButtonContentState extends State<_BookRoomButtonContent> {
  bool _pressed = false;

  Color get _background =>
      _pressed ? SalangaColors.burgundyHover : SalangaColors.burgundy;

  double get _iconSize {
    if (widget.promoBar) return 28;
    return widget.compact ? 22 : 26;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.promoBar
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(kHomeBannerRadius),
            bottomRight: Radius.circular(kHomeBannerRadius),
          )
        : BorderRadius.circular(28);

    return Material(
      color: _background,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onPressed,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.promoBar ? 20 : (widget.compact ? 16 : 20),
            vertical: widget.promoBar ? 14 : (widget.compact ? 12 : 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: widget.promoBar ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Image.asset(
                SalangaAssets.bookRoom,
                width: _iconSize,
                height: _iconSize,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: widget.promoBar ? 16 : (widget.compact ? 15 : 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookRoomPromoCard extends StatelessWidget {
  const BookRoomPromoCard({
    this.imageUrl,
    this.title,
    this.subtitle,
    super.key,
  });

  final String? imageUrl;
  final String? title;
  final String? subtitle;

  bool get _hasSlogan {
    final t = title?.trim() ?? '';
    final s = subtitle?.trim() ?? '';
    return t.isNotEmpty || s.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveBannerMediaUrl(imageUrl ?? '');
    final hasNetwork = resolved.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = kHomeTopBannerHeight(constraints.maxWidth);
        return ClipRRect(
          borderRadius: BorderRadius.circular(kHomeBannerRadius),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: SalangaColors.textDark,
                  child: AdminBannerImage(
                    imageUrl: hasNetwork ? resolved : null,
                    sortOrder: 0,
                  ),
                ),
                if (_hasSlogan) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: _PromoSlogan(title: title, subtitle: subtitle),
                  ),
                ],
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BookRoomButton(fullWidth: true, promoBar: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PromoSlogan extends StatelessWidget {
  const _PromoSlogan({this.title, this.subtitle});

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final lineStyle = GoogleFonts.ptSerif(
      color: Colors.white,
      fontSize: 22,
      height: 1.15,
      fontWeight: FontWeight.w600,
      shadows: const [
        Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 1)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.trim().isNotEmpty)
          Text(title!.trim(), style: lineStyle),
        if (subtitle != null && subtitle!.trim().isNotEmpty)
          Text(subtitle!.trim(), style: lineStyle),
      ],
    );
  }
}
