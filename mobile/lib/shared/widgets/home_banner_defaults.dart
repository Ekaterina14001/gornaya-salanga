/// Fallback images from [salanga.ru](https://www.salanga.ru) when API is unavailable.
class HomeBannerDefaults {
  static const _base = 'https://www.salanga.ru';

  static const topImage = '$_base/up/17/51a5c408d8-glavnayazima-02.jpg';
  static const bottomLeft = '$_base/up/room/nomer-04.jpg';
  static const bottomRight =
      '$_base/yiiassets/easyimage/6/6917b199b8c40571210a89edf50a2b25.jpg';

  static int sortOrderFromJson(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static String forSortOrder(int sortOrder) {
    switch (sortOrder) {
      case 0:
        return topImage;
      case 1:
        return bottomLeft;
      case 2:
        return bottomRight;
      default:
        return topImage;
    }
  }

  static String effective(String? stored, int sortOrder) {
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();
    return forSortOrder(sortOrder);
  }

  /// Если в API только верхний слот (0), добавляем дефолтную нижнюю карусель с salanga.ru.
  static List<Map<String, dynamic>> mergeWithDefaultCarousel(
    List<Map<String, dynamic>> fromApi,
  ) {
    final list = fromApi.map((e) => Map<String, dynamic>.from(e)).toList();
    final hasBottom =
        list.any((b) => sortOrderFromJson(b['sortOrder']) > 0);
    if (hasBottom) return list;
    for (final entry in defaultEntries()) {
      if (sortOrderFromJson(entry['sortOrder']) > 0) {
        list.add(Map<String, dynamic>.from(entry));
      }
    }
    list.sort((a, b) => sortOrderFromJson(a['sortOrder'])
        .compareTo(sortOrderFromJson(b['sortOrder'])));
    return list;
  }

  /// sortOrder 0 → верх; 1+ → нижняя карусель. Один баннер без слота 0 — только верх.
  static ({Map<String, dynamic>? top, List<Map<String, dynamic>> bottom}) splitBySlot(
    List<Map<String, dynamic>> banners,
  ) {
    final sorted = List<Map<String, dynamic>>.from(banners)
      ..sort((a, b) => sortOrderFromJson(a['sortOrder']).compareTo(sortOrderFromJson(b['sortOrder'])));

    final topSlots =
        sorted.where((b) => sortOrderFromJson(b['sortOrder']) == 0).toList();
    var bottom =
        sorted.where((b) => sortOrderFromJson(b['sortOrder']) > 0).toList();

    Map<String, dynamic>? top;
    if (topSlots.isNotEmpty) {
      top = topSlots.first;
    } else if (sorted.length == 1) {
      top = sorted.first;
      bottom = [];
    }

    return (top: top, bottom: bottom);
  }

  /// Локальный fallback, если API не вернул баннеры (совпадает с бэкендом).
  static List<Map<String, dynamic>> defaultEntries() => [
        {
          'sortOrder': 0,
          'imageUrl': topImage,
          'linkUrl': '$_base/book/',
          'title': 'Жить в шале,',
          'subtitle': 'просыпаться в тайге',
        },
        {
          'sortOrder': 1,
          'imageUrl': bottomLeft,
          'linkUrl': _base,
          'title': 'Добро пожаловать в Горную Салангу',
        },
        {
          'sortOrder': 2,
          'imageUrl': bottomRight,
          'linkUrl': '$_base/book/',
          'title': '',
        },
      ];
}
