import 'package:flutter_test/flutter_test.dart';
import 'package:gornaya_salanga/shared/widgets/home_banner_defaults.dart';

void main() {
  group('HomeBannerDefaults.splitBySlot', () {
    test('sort 0 top, 1+ in bottom carousel', () {
      final banners = [
        {'sortOrder': 1, 'title': 'bottom1'},
        {'sortOrder': 0, 'title': 'top'},
        {'sortOrder': 2, 'title': 'bottom2'},
      ];
      final split = HomeBannerDefaults.splitBySlot(banners);
      expect(split.top?['title'], 'top');
      expect(split.bottom.map((b) => b['title']), ['bottom1', 'bottom2']);
    });

    test('single banner without slot 0 stays top only', () {
      final split = HomeBannerDefaults.splitBySlot([
        {'sortOrder': 3, 'title': 'only'},
      ]);
      expect(split.top?['title'], 'only');
      expect(split.bottom, isEmpty);
    });

    test('only bottom slots — no top', () {
      final split = HomeBannerDefaults.splitBySlot([
        {'sortOrder': 1, 'title': 'a'},
        {'sortOrder': 2, 'title': 'b'},
      ]);
      expect(split.top, isNull);
      expect(split.bottom.length, 2);
    });
  });

  group('mergeWithDefaultCarousel', () {
    test('adds default lower slides when API has only top', () {
      final merged = HomeBannerDefaults.mergeWithDefaultCarousel([
        {'sortOrder': 0, 'imageUrl': 'https://example.com/top.jpg'},
      ]);
      expect(merged.length, greaterThanOrEqualTo(3));
      expect(
        merged.where((b) => HomeBannerDefaults.sortOrderFromJson(b['sortOrder']) > 0).length,
        greaterThanOrEqualTo(2),
      );
    });
  });
}
