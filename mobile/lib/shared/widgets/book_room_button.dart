import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/navigation/app_link.dart';
import '../../core/theme/salanga_colors.dart';
import '../../l10n/app_localizations.dart';

const kSalangaBookingUrl = 'https://www.salanga.ru/book/';

class BookRoomButton extends StatelessWidget {
  const BookRoomButton({
    super.key,
    this.compact = false,
    this.fullWidth = true,
  });

  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final child = _BookRoomButtonContent(
      label: l10n.bookRoom,
      compact: compact,
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
    required this.onPressed,
  });

  final String label;
  final bool compact;
  final VoidCallback onPressed;

  @override
  State<_BookRoomButtonContent> createState() => _BookRoomButtonContentState();
}

class _BookRoomButtonContentState extends State<_BookRoomButtonContent> {
  bool _pressed = false;

  Color get _background =>
      _pressed ? SalangaColors.burgundyHover : SalangaColors.burgundy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onPressed,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 16 : 20,
            vertical: widget.compact ? 12 : 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hotel_outlined,
                color: Colors.white,
                size: widget.compact ? 22 : 26,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontSize: widget.compact ? 15 : 16,
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
  const BookRoomPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SalangaColors.textDark,
            Color(0xFF392D23),
          ],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Жить в шале,\nпросыпаться в тайге',
            style: GoogleFonts.ptSerif(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Подберите номер на официальном сайте курорта',
            style: GoogleFonts.openSans(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const BookRoomButton(fullWidth: true),
        ],
      ),
    );
  }
}
