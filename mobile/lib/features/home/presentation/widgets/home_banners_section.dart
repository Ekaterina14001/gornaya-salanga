import 'package:flutter/material.dart';

import '../../../../core/network/media_url.dart';
import '../../../../shared/widgets/book_room_button.dart';
import '../../../../shared/widgets/home_banner_defaults.dart';
import '../../../catalog/data/content_repository.dart';
import 'headliners_carousel.dart';

/// sortOrder 0 → верх с кнопкой «Забронировать»; 1, 2, 3… → нижняя карусель (свайп).
class HomeBannersSection extends StatefulWidget {
  const HomeBannersSection({super.key});

  static Future<void> refreshActive({bool forceRefresh = true}) {
    return _HomeBannersSectionState.refreshActive(forceRefresh: forceRefresh);
  }

  @override
  State<HomeBannersSection> createState() => _HomeBannersSectionState();
}

class _HomeBannersSectionState extends State<HomeBannersSection> {
  static _HomeBannersSectionState? _active;

  final _repo = ContentRepository();
  List<Map<String, dynamic>> _banners = [];

  static Future<void> refreshActive({bool forceRefresh = true}) {
    return _active?._load(forceRefresh: forceRefresh) ?? Future.value();
  }

  @override
  void initState() {
    super.initState();
    _active = this;
    _load(forceRefresh: true);
  }

  @override
  void dispose() {
    if (_active == this) _active = null;
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    try {
      final data = await _repo.fetchHeadliners(forceRefresh: forceRefresh);
      if (!mounted) return;
      var list = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (list.isEmpty) {
        list = HomeBannerDefaults.defaultEntries();
      }
      list = HomeBannerDefaults.mergeWithDefaultCarousel(list);
      if (!mounted) return;
      setState(() => _banners = list);
    } catch (_) {
      if (mounted) {
        setState(() => _banners = HomeBannerDefaults.defaultEntries());
      }
    }
  }

  String _imageFor(Map<String, dynamic> banner) {
    final sort = HomeBannerDefaults.sortOrderFromJson(banner['sortOrder']);
    final raw = banner['imageUrl']?.toString();
    return resolveBannerMediaUrl(HomeBannerDefaults.effective(raw, sort));
  }

  ({Map<String, dynamic>? top, List<Map<String, dynamic>> bottom}) _splitSlots() =>
      HomeBannerDefaults.splitBySlot(_banners);

  @override
  Widget build(BuildContext context) {
    final slots = _splitSlots();
    final topImage = slots.top != null
        ? _imageFor(slots.top!)
        : HomeBannerDefaults.topImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookRoomPromoCard(
          key: ValueKey(topImage),
          imageUrl: topImage.isNotEmpty ? topImage : null,
          title: slots.top?['title']?.toString(),
          subtitle: slots.top?['subtitle']?.toString(),
        ),
        if (slots.bottom.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: HeadlinersCarousel(
              key: ValueKey(slots.bottom.map((b) => '${b['id']}-${b['imageUrl']}').join('|')),
              bottomBanners: slots.bottom,
            ),
          ),
        ],
      ],
    );
  }
}
