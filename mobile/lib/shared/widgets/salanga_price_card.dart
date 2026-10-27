import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/salanga_colors.dart';

/// Карточка раздела прайса (макет «Услуги»).
class SalangaPriceCard extends StatelessWidget {
  const SalangaPriceCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SalangaColors.priceCardBodyBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SalangaColors.priceCardDivider, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            color: SalangaColors.priceCardHeaderBg,
            child: Text(
              title,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.openSans(
                fontSize: 30,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: SalangaColors.priceCardHeaderText,
              ),
            ),
          ),
          ColoredBox(
            color: SalangaColors.priceCardBodyBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _intersperseDividers(children),
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _intersperseDividers(List<Widget> items) {
    if (items.isEmpty) return items;
    final out = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      out.add(const SalangaPriceDivider());
      out.add(items[i]);
    }
    return out;
  }
}

class SalangaPriceDivider extends StatelessWidget {
  const SalangaPriceDivider({super.key, this.indent = 16});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: indent,
      color: SalangaColors.priceCardDivider,
    );
  }
}

/// «час / день» над таблицей проката (правая выключка).
class SalangaPriceRentalColumnHeader extends StatelessWidget {
  const SalangaPriceRentalColumnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          'час / день',
          textScaler: TextScaler.noScaling,
          style: GoogleFonts.openSans(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: SalangaColors.priceCardRentalColumn,
          ),
        ),
      ),
    );
  }
}

/// Подзаголовок внутри карточки (например, «Горные лыжи (комплект)»).
class SalangaPriceGroupTitle extends StatelessWidget {
  const SalangaPriceGroupTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        text,
        textScaler: TextScaler.noScaling,
        style: GoogleFonts.openSans(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: SalangaColors.priceCardGroupTitle,
        ),
      ),
    );
  }
}

/// Строка: подпись слева, значение справа.
class SalangaPriceLine extends StatelessWidget {
  const SalangaPriceLine({
    super.key,
    required this.label,
    this.trailing,
    this.dense = false,
  });

  final String label;
  final String? trailing;
  final bool dense;

  static TextStyle get _rowStyle => GoogleFonts.openSans(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w400,
        color: SalangaColors.priceCardRowText,
      );

  @override
  Widget build(BuildContext context) {
    final showTrailing = trailing != null && trailing!.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: dense ? 8 : 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              textScaler: TextScaler.noScaling,
              style: _rowStyle,
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            Text(
              trailing!,
              textAlign: TextAlign.right,
              textScaler: TextScaler.noScaling,
              style: _rowStyle,
            ),
          ],
        ],
      ),
    );
  }
}

/// Примечание внутри карточки.
class SalangaPriceFootnote extends StatelessWidget {
  const SalangaPriceFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
        style: GoogleFonts.openSans(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w400,
          color: SalangaColors.priceCardRowText,
        ),
      ),
    );
  }
}
