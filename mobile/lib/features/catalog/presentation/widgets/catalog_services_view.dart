import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/salanga_colors.dart';
import '../../../../shared/widgets/salanga_price_card.dart';

/// Текст под таблицей «Подъёмники» (не из API — строки «бесплатно» в прайсе не показываем).
const kLiftFreeServicesFootnote =
    'Подъёмник от озера и детский подъёмник (бэби-лифт) — бесплатные';

/// Вкладка «Услуги» — карточки по макету (данные с API без поломки парсинга).
class CatalogServicesView extends StatelessWidget {
  const CatalogServicesView({super.key, required this.services});

  final List<Map<String, dynamic>> services;

  static const _categoryLabels = {
    'lift': 'Подъёмники',
    'rental': 'Прокат',
    'tubing': 'Сноутюбинг',
    'snowmobile': 'Снегоходный маршрут',
    'other': 'Прочее',
  };

  static const _categoryOrder = [
    'lift',
    'tubing',
    'snowmobile',
    'rental',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in services) {
      final cat = s['category']?.toString() ?? 'other';
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    final categories = [
      ..._categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_categoryOrder.contains(k)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final cat in categories) ...[
          SalangaPriceCard(
            title: _categoryLabels[cat] ?? cat,
            children: _cardChildren(cat, grouped[cat]!),
          ),
          if (cat == 'lift') ...[
            const SizedBox(height: 12),
            const _LiftFreeFootnote(text: kLiftFreeServicesFootnote),
          ],
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<Widget> _cardChildren(String category, List<Map<String, dynamic>> items) {
    final widgets = <Widget>[];
    final isRental = category == 'rental';
    final isLift = category == 'lift';

    if (isRental && _hasRentalTable(items)) {
      widgets.add(const SalangaPriceRentalColumnHeader());
    }

    for (final s in items) {
      final name = s['name']?.toString().trim() ?? '';
      final desc = s['description']?.toString().trim() ?? '';
      final priceLabel = _displayPrice(s['price']);

      if (isLift &&
          (_isLiftFreeRow(name, desc, s['price']) ||
              priceLabel == 'бесплатно')) {
        continue;
      }

      if (_isFootnoteRow(name, desc, s['price'])) {
        if (isLift) continue;
        widgets.add(SalangaPriceFootnote(desc.isNotEmpty ? desc : name));
        continue;
      }

      if (isRental && desc.isNotEmpty) {
        widgets.add(SalangaPriceGroupTitle(name));
        for (final part in desc.split(';')) {
          final line = part.trim();
          if (line.isEmpty) continue;
          final parsed = _parseRentalLine(line);
          widgets.add(
            SalangaPriceLine(
              label: parsed.$1,
              trailing: parsed.$2,
              dense: true,
            ),
          );
        }
        continue;
      }

      if (name.isEmpty) continue;

      widgets.add(SalangaPriceLine(label: name, trailing: priceLabel));
    }

    return widgets;
  }

  static bool _hasRentalTable(List<Map<String, dynamic>> items) {
    for (final s in items) {
      final desc = s['description']?.toString().trim() ?? '';
      if (desc.isNotEmpty) return true;
    }
    return false;
  }

  /// «взрослый: 300 / 1500» → (взрослый, 300 / 1500).
  static (String, String?) _parseRentalLine(String line) {
    final colon = line.indexOf(':');
    if (colon > 0) {
      final label = line.substring(0, colon).trim();
      final prices = line.substring(colon + 1).trim();
      if (prices.isNotEmpty) return (label, prices);
      return (label, null);
    }
    final match = RegExp(r'^(.+?)\s+(\d[\d\s]*/\s*\d+.*)$').firstMatch(line);
    if (match != null) {
      return (match.group(1)!.trim(), match.group(2)!.trim());
    }
    return (line, null);
  }

  /// Строки прайса «Подъёмники» с нулевой ценой / «бесплатно» — только подпись под таблицей.
  static bool _isLiftFreeRow(String name, String desc, dynamic price) {
    final p = _priceNum(price);
    if (p != null && p == 0) return true;
    final text = '$name $desc'.toLowerCase();
    if (text.contains('бесплат')) return true;
    if (name.isEmpty && (p == null || p == 0)) return true;
    return false;
  }

  static bool _isFootnoteRow(String name, String desc, dynamic price) {
    final p = _priceNum(price);
    if (p != null && p != 0) return false;
    final text = '$name $desc'.toLowerCase();
    return text.contains('бесплат') || name.length > 52;
  }

  static num? _priceNum(dynamic price) {
    if (price == null) return null;
    if (price is num) return price;
    final raw = price.toString().trim().toLowerCase();
    if (raw.contains('бесплат') || raw == 'free') return 0;
    return num.tryParse(raw.replaceAll(',', '.'));
  }

  static String _displayPrice(dynamic price) {
    final value = _priceNum(price);
    if (value == null) return '';
    if (value == 0) return 'бесплатно';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}

class _LiftFreeFootnote extends StatelessWidget {
  const _LiftFreeFootnote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.left,
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
